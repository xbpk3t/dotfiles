#!/usr/bin/env nu

# nixos-anywhere 远程刷机脚本
#
# 设计要点:
#   - 默认 dry-run：只做本地/远端 preflight 并打印命令，不 staging、不安装
#   - STAGED=true：kexec -> installer 检查/自动启用旧 swap -> 确认 ->
#     disko,install -> 安装后检查（不自动 reboot）；检测到阻塞问题会中止
#   - PHASES 是唯一阶段来源；NA_ARGS 只放额外 nixos-anywhere flags
#   - 主 preflight 在 *单次 SSH 连接* 中完成 → 只输一次密码；key-auth 用 BatchMode 单独探测
#   - age key 只在 --execute 时 staging；/tmp 下 700 目录 + 600 文件，shell trap 保证 Ctrl-C 也清理
#   - 本地已有 nixos-anywhere 则直接调用，否则用 nix run 回退（--refresh 不锁版本）
#
# 用法:
#   nu .taskfile/nix/scripts/nixos-anywhere.nu --flake "path#host" --host "root@ip" --disk /dev/vda
#   nu .taskfile/nix/scripts/nixos-anywhere.nu --flake "path#host" --host "root@ip" --staged
#   nu .taskfile/nix/scripts/nixos-anywhere.nu --flake "path#host" --host "root@ip" --phases kexec
#   nu .taskfile/nix/scripts/nixos-anywhere.nu --flake "path#host" --host "root@ip" \
#     --age-key "$HOME/Library/Application Support/sops/age/keys.txt" --execute
#
# NA_ARGS 按空格拆分；值里含空格/引号时无法可靠传参，请避免。

const INSTALL_CHECK_FAILED = '安装后检查未通过；请勿 reboot，先人工检查 /mnt/boot/initrd 与 /mnt/etc/fstab'
const NONINTERACTIVE_MSG = '非交互环境请用 PHASES=kexec + PHASES=disko,install，或 STAGED_YES=true'

def main [
    --flake: string = ''                # flake 引用（<flakeref>#<NODE>）
    --host: string = ''                 # 目标 SSH（root@ip）
    --phases: string = ''               # 逗号分隔；空则默认 kexec,disko,install
    --staged                            # kexec -> 检查/启旧 swap -> 确认 -> disko,install
    --yes                               # STAGED 模式下跳过 Enter 确认
    # Why 加 --option pure-eval false：仓库依赖 impure eval（未 track 源码目录），
    # nixos-anywhere 没有 --impure，但可以把该选项透传给内部 nix。
    --na-args: string = '--debug --option pure-eval false'  # 透传给 nixos-anywhere 的额外参数（按空格拆分）
    --age-key: string = ''              # 可选：age key 路径；注入 home/luck/.config/sops/age/keys.txt
    --disk: string = '/dev/vda'         # 目标盘；必须与目标 host 的 disko.nix 一致
    --execute                           # 设此标志则真正执行，否则 dry-run
]: nothing -> nothing {
    let phases_explicit = not ($phases | str trim | is-empty)
    if $staged and $phases_explicit {
        error make {msg: 'STAGED=true 与 PHASES 二选一'}
    }
    if $yes and not $staged {
        error make {msg: '--yes 只能与 --staged 一起使用'}
    }
    # 只在入口解析一次；下游按 list 做成员判断，传给 nixos-anywhere 时再 join。
    let phase_list = (
        (if $phases_explicit { $phases } else { 'kexec,disko,install' })
        | split row ','
        | each {|x| $x | str trim }
        | where {|x| $x | is-not-empty }
    )
    let phases = $phase_list | str join ','

    # ── [1/3] 本地 preflight ──────────────────────────
    print '◆ [1/3] 本地环境检查'
    (check-local
        $flake
        $host
        $na_args
        $age_key
        $disk
        $phase_list
        $staged
        $execute
    )
    print '  ✓ 全部通过'
    print ''

    print $'■ nixos-anywhere: FLAKE=($flake) HOST=($host) DISK=($disk) PHASES=($phases) STAGED=($staged)'
    print ''
    print ''

    # ── [2/3] 远端 preflight（单次 SSH）───────────────
    print '◆ [2/3] 远端环境检查'
    let key_auth = (check-remote $host $disk)
    print ''

    # ── [3/3] 执行 ──────────────────────────────────
    print '◆ [3/3] nixos-anywhere 计划'

    if not $execute {
        print-plan $flake $host $na_args $age_key $phases $staged
        print ''
        print '⚠ DRY-RUN: 未 staging age key、未执行安装；加 --execute 以真正执行'
        return
    }

    # execute 前最后一道本地门禁：host 必须可 eval（dry-run 不跑，避免慢 eval）
    check-flake-attr $flake

    print ''

    if $staged {
        let plan = (staged-plan $age_key)
        run-na $flake $host $na_args $plan.kexec.age_key $plan.kexec.extra
        if not (post-kexec-check $host $disk $key_auth $staged) {
            error make {
                msg: 'installer 检查发现阻塞问题；已停在 installer，修复后可用 PHASES=disko,install 继续'
            }
        }
        confirm-stage2 $yes
        run-na $flake $host $na_args $plan.install.age_key $plan.install.extra
        if not (post-install-check $host $key_auth $staged) {
            error make {msg: $INSTALL_CHECK_FAILED}
        }
    } else {
        run-na $flake $host $na_args $age_key ['--phases', $phases]

        if (has-phase $phase_list 'kexec') and not (has-phase $phase_list 'disko') and not (has-phase $phase_list 'install') {
            let kexec_ok = (post-kexec-check $host $disk $key_auth $staged)
            print-next-step $flake $host $disk $age_key $na_args
            if not $kexec_ok {
                error make {
                    msg: 'installer 检查发现阻塞问题；修复后按上面的命令继续'
                }
            }
        }
        if (has-phase $phase_list 'install') and not (post-install-check $host $key_auth $staged) {
            error make {msg: $INSTALL_CHECK_FAILED}
        }
    }

    print '✓ 完成'

    # 只有实际执行了 install，首启验收清单才有意义；kexec/reboot-only 不打印。
    if (has-phase $phase_list 'install') {
        print ''
        print '后续（首启验收）:'
        print $'  1. ssh-keygen -R ($host | split row "@" | last)（kexec 后 host key 已变化；accept-new 不接受变更后的 key）'
        print '  2. 检查 hostname / id / linger / sops / sshd / firewall / virtio / fstab / disk'
        print '  3. 若未用 --chown 注入：chown -R luck:users /home/luck 后再 deploy'
        print '  4. 若用了 --phases 未 reboot：先在 installer 检查 /mnt/boot/initrd 含 virtio'
    }
}

# ═══════════════  helpers  ═══════════════

def validate-phases [phases: list<string>]: nothing -> nothing {
    let allowed = ['kexec' 'disko' 'install' 'reboot']
    if ($phases | is-empty) {
        error make {msg: 'PHASES 不能为空'}
    }
    let bad = $phases | where {|x| not ($x in $allowed) }
    if ($bad | is-not-empty) {
        error make {msg: $'PHASES 含未知阶段: ($bad | str join ", ")'}
    }
}

def has-phase [phases: list<string>, phase: string]: nothing -> bool {
    $phase in $phases
}

# 打印给用户复制的命令需要 shell-safe quoting。
# BSD/macOS 的 /usr/bin/printf 不支持 %q，统一走 bash 内建 printf。
def shquote [value: string]: nothing -> string {
    let res = (^bash -c 'printf %q "$1"' _ $value | complete)
    if $res.exit_code != 0 {
        error make {msg: $'shquote 失败: ($res.stderr | str trim)'}
    }
    # 只去掉可能的行尾换行；printf %q 会把行尾空格转义成 `\ `，不能 trim 掉。
    $res.stdout | str replace -r '\r?\n$' ''
}

# installer 的 host key 在 kexec 后会变化；known_hosts 里的旧条目会让
# StrictHostKeyChecking=accept-new 拒绝连接。与 nixos-anywhere 自身一致：
# 对临时 installer 会话不校验 host key。
def ssh-installer [host: string, script: string]: nothing -> record {
    ^ssh -o BatchMode=yes -o ConnectTimeout=10 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $host $script | complete
}

# installer 不可达时的统一策略：STAGED 或 key auth 正常 → 阻塞；否则降级为告警。
def handle-installer-unreachable [
    res: record
    key_auth: bool
    staged: bool
    what: string
    manual: string
]: nothing -> bool {
    if $key_auth or $staged {
        print $'  ✗ 无法 SSH 到 installer: ($res.stderr | str trim)'
        false
    } else {
        print $'  ⚠ 无法 SSH 到 installer（preflight 未配置 key auth，跳过 ($what)）: ($res.stderr | str trim)'
        print $manual
        true
    }
}

def na-runner []: nothing -> list<string> {
    if (which nixos-anywhere | length) > 0 {
        ['nixos-anywhere']
    } else {
        ['nix', 'run', '--refresh', 'github:nix-community/nixos-anywhere', '--']
    }
}

def print-na-command [
    flake: string
    host: string
    na_args: string
    age_key: string
    extra: list<string>
]: nothing -> nothing {
    let runner = (na-runner | str join ' ')
    let extra_str = $extra | str join ' '
    let base = $na_args + ' ' + $extra_str | str trim
    let display_args = if ($age_key | str trim | is-not-empty) {
        $base + ' --extra-files <age-key-stage> --chown home/luck 1000:100'
    } else {
        $base
    }
    let cmd_display = $'  ($runner) --flake ($flake) --target-host ($host) ($display_args)'
    print '  ──────────────────────────────────────────────'
    print $cmd_display
    print '  ──────────────────────────────────────────────'
}

# dry-run 与 execute 共用同一份 staged 步骤定义，避免计划与实际执行漂移。
def staged-plan [age_key: string]: nothing -> record {
    {
        kexec: {
            age_key: ''
            extra: ['--phases', 'kexec']
        }
        install: {
            age_key: $age_key
            extra: ['--phases', 'disko,install', '--no-substitute-on-destination']
        }
    }
}

def print-plan [
    flake: string
    host: string
    na_args: string
    age_key: string
    phases: string
    staged: bool
]: nothing -> nothing {
    if $staged {
        print '  plan: kexec -> installer 检查/自动启用旧 swap -> 确认 -> disko,install -> 安装后检查'
        let plan = (staged-plan $age_key)
        print-na-command $flake $host $na_args $plan.kexec.age_key $plan.kexec.extra
        print-na-command $flake $host $na_args $plan.install.age_key $plan.install.extra
    } else {
        (print-na-command
            $flake
            $host
            $na_args
            $age_key
            ['--phases', $phases]
        )
    }
}

def print-next-step [
    flake: string
    host: string
    disk: string
    age_key: string
    na_args: string
]: nothing -> nothing {
    let extra = if ($na_args | str contains '--no-substitute-on-destination') {
        ''
    } else {
        ' --no-substitute-on-destination'
    }
    let na_value = $na_args + $extra | str trim
    let age = if ($age_key | str trim | is-not-empty) {
        ' AGE_KEY=' + (shquote $age_key)
    } else {
        ''
    }
    let flake_q = (shquote $flake)
    print ''
    print '  · installer 已就绪；继续安装（不自动 reboot）：'
    print $'    task nix:nixos-anywhere FLAKE=($flake_q) HOST=(shquote $host) DISK=(shquote $disk) PHASES="disko,install"($age) NA_ARGS=(shquote $na_value) STAGED=false STAGED_YES=false DRY_RUN=false CONFIRM=($flake_q)'
}

def run-na [
    flake: string
    host: string
    na_args: string
    age_key: string
    extra: list<string>
]: nothing -> nothing {
    let age = (stage-age-key $age_key)
    let args = [
        ...['--flake', $flake, '--target-host', $host]
        ...($na_args | split row ' ' | where {|x| $x | is-not-empty })
        ...$extra
        ...$age.extra_args
    ]
    let runner = (na-runner)

    print-na-command $flake $host $na_args $age_key $extra
    print ''
    print '◆ 开始执行...'

    try {
        if ($age.dir | is-not-empty) {
            # shell trap：正常退出、INT、TERM 都清理明文 key
            let trap_script = '
cleanup() { s=$?; trap - EXIT INT TERM; rm -rf "$STAGE_DIR"; exit $s; }
trap cleanup EXIT
trap "exit 130" INT
trap "exit 143" TERM
"$@"
'
            with-env { STAGE_DIR: $age.dir } { ^sh -c $trap_script _ ...$runner ...$args }
        } else {
            with-env { STAGE_DIR: '' } { ^sh -c '"$@"' _ ...$runner ...$args }
        }
    } catch {|err|
        cleanup-stage $age.dir
        error make {msg: $'nixos-anywhere 执行失败: ($err.msg)'}
    }

    cleanup-stage $age.dir
    print '✓ phase 完成'
}

def confirm-stage2 [yes: bool]: nothing -> nothing {
    if $yes {
        return
    }
    # input 在非 TTY 下的行为因版本而异；先显式检查 stdin，避免静默通过。
    let tty = (^sh -c 'test -t 0' | complete)
    if $tty.exit_code != 0 {
        error make {msg: $NONINTERACTIVE_MSG}
    }
    print '◆ 已停在 installer；按 Enter 继续 disko,install，Ctrl-C 退出'
    try {
        input | ignore
    } catch {|_|
        error make {msg: $NONINTERACTIVE_MSG}
    }
}

def post-kexec-check [
    host: string
    disk: string
    key_auth: bool
    staged: bool
]: nothing -> bool {
    print '◆ installer 内存/swap 检查'
    let mem = (ssh-installer $host 'free -m; echo ---; swapon --show')
    if $mem.exit_code != 0 {
        return (handle-installer-unreachable $mem $key_auth $staged '自动检查' '    手动检查：ssh root@<ip> "free -m; swapon --show"；1 GiB 机器必要时手动 swapon')
    }
    print $mem.stdout

    # lsblk 单独执行并在本地解析：远程 pipeline 的退出码来自最后一个命令，
    # lsblk 失败会被 grep/cut 掩盖。
    let swaps = (ssh-installer $host $"lsblk -rno NAME,FSTYPE ($disk)")
    if $swaps.exit_code != 0 {
        print $'  ✗ 无法枚举旧 swap: ($swaps.stderr | str trim)'
        return false
    }
    let swap_devs = (
        $swaps.stdout
        | lines
        | each {|line| $line | str trim | split row -r '\s+' }
        | where {|cols| ($cols | length) >= 2 and ($cols | last) == 'swap' }
        | each {|cols| $'/dev/($cols | first)' }
    )
    let active_swaps = (
        $mem.stdout
        | lines
        | each {|line| $line | str trim | split row -r '\s+' | first }
        | where {|x| $x | str starts-with '/dev/' }
    )

    for dev in $swap_devs {
        if $dev in $active_swaps {
            continue
        }
        print $'  · 启用旧 swap ($dev)'
        let r = (ssh-installer $host ('swapon ' + (shquote $dev)))
        if $r.exit_code != 0 {
            print $'  ✗ swapon 失败: ($r.stderr | str trim)'
            return false
        }
    }
    print '  · 继续前确认 free -m 余量；Ctrl-C 可停在 installer'
    true
}

def post-install-check [host: string, key_auth: bool, staged: bool]: nothing -> bool {
    print '◆ 安装后检查（未 reboot）'
    let res = (
        ssh-installer $host '
        if command -v lsinitrd >/dev/null 2>&1; then
          lsinitrd /mnt/boot/initrd | grep -q virtio && echo "initrd: virtio OK" || echo "initrd: virtio MISSING"
        elif command -v zstdcat >/dev/null 2>&1; then
          zstdcat /mnt/boot/initrd | grep -a -q virtio && echo "initrd: virtio OK" || echo "initrd: virtio MISSING"
        elif command -v xzcat >/dev/null 2>&1; then
          xzcat /mnt/boot/initrd | grep -a -q virtio && echo "initrd: virtio OK" || echo "initrd: virtio MISSING"
        elif command -v gzip >/dev/null 2>&1; then
          gzip -dc /mnt/boot/initrd | grep -a -q virtio && echo "initrd: virtio OK" || echo "initrd: virtio MISSING"
        else
          echo "initrd: 请手动检查"
        fi
        echo "swap_fstab=$(grep -c NIXOS_SWAP /mnt/etc/fstab || true)"
        findmnt --verify --tab-file /mnt/etc/fstab || echo "fstab: verify FAILED"
        df -h /mnt
    '
    )
    if $res.exit_code != 0 {
        return (handle-installer-unreachable $res $key_auth $staged '安装后检查' '    手动检查：/mnt/boot/initrd、/mnt/etc/fstab、df -h /mnt')
    }
    print $res.stdout

    let virtio_missing = $res.stdout | str contains 'virtio MISSING'
    let initrd_manual = $res.stdout | str contains '请手动检查'
    let fstab_failed = $res.stdout | str contains 'fstab: verify FAILED'

    if $virtio_missing {
        print '  ✗ initrd 不含 virtio 驱动；直接重启会失去磁盘/网络'
        return false
    }
    if $fstab_failed {
        print '  ✗ fstab 校验失败；请勿 reboot'
        return false
    }
    if $initrd_manual {
        print '  ⚠ 无法自动验证 initrd，请人工确认'
        print '  · 人工确认 /mnt/boot/initrd 后再 reboot'
    } else {
        print $'  · 确认无误后：ssh root@($host | split row "@" | last) "sync; umount -R /mnt; reboot"'
    }
    true
}

# 本地环境检查：格式、flake 可见性、age key、disk、phases
def check-local [
    flake: string
    host: string
    na_args: string
    age_key: string
    disk: string
    phases: list<string>
    staged: bool
    execute: bool
]: nothing -> nothing {
    if ($flake | str trim | is-empty) {
        error make {msg: '缺少 FLAKE（例：./dotfiles#nixos-vps）'}
    }
    if not ('#' in $flake) {
        error make {msg: 'FLAKE 必须包含 #（例：./dotfiles#my-host）'}
    }
    if ($host | str trim | is-empty) {
        error make {msg: '缺少 HOST（例：root@1.2.3.4）'}
    }
    if (which ssh | length) == 0 {
        error make {msg: '本地缺少 ssh'}
    }
    if (which nix | length) == 0 {
        error make {msg: '本地缺少 nix（用于回退: nix run）'}
    }
    if ($na_args | str contains '--flake') or ($na_args | str contains '--target-host') {
        error make {
            msg: 'NA_ARGS 不能包含 --flake/--target-host；用 FLAKE/HOST 指定目标'
        }
    }
    if ($na_args | str contains '--phases') {
        error make {
            msg: 'NA_ARGS 不能包含 --phases；用 PHASES=kexec|disko,install|... 指定阶段'
        }
    }
    if $staged and ($na_args | str contains '--no-substitute-on-destination') {
        error make {
            msg: 'STAGED=true 已自动加 --no-substitute-on-destination；不要重复放在 NA_ARGS'
        }
    }
    if ($age_key | str trim | is-not-empty) and ($na_args | str contains '--extra-files') {
        error make {
            msg: 'NA_ARGS 已包含 --extra-files；请把 age key 放进该目录，或去掉 --age-key'
        }
    }
    if not ($disk =~ '^/dev/[A-Za-z0-9/_.:-]+$') {
        error make {msg: $'DISK 格式不合法: ($disk)'}
    }

    validate-phases $phases
    # reboot 只能单独使用；install 后立刻 reboot 会跳过安装后检查。
    if (has-phase $phases 'reboot') and ($phases | length) > 1 {
        error make {
            msg: 'reboot 只能单独使用；install 后请先验证 initrd/fstab，再手动 reboot'
        }
    }
    if (has-phase $phases 'install') and ($age_key | str trim | is-empty) {
        if $execute {
            error make {
                msg: 'install phase 必须指定 AGE_KEY；否则 ME_PASS_HASH 等 neededForUsers secrets 无法解密。若目标确实不需要 sops，请直接运行 nixos-anywhere'
            }
        }
        print '  ⚠ install phase 未指定 AGE_KEY：sops secrets（ME_PASS_HASH 等）不会注入（dry-run 允许）'
    }
    if (has-phase $phases 'install') and not $staged and not ($na_args | str contains '--no-substitute-on-destination') {
        print '  · install phase 建议加 --no-substitute-on-destination（installer 可能无 DNS；STAGED 模式会自动加）'
    }

    check-flake-visibility $flake
    print '  · closure 门禁：nix path-info -S <toplevel>；>1.7G 先刷 system-only，再用 deploy-rs 推 home'
    check-age-key $age_key
}

# flake 可见性：untracked 不可见；path: 会把 untracked/ignored/.git 拷入 world-readable store
def check-flake-visibility [flake: string]: nothing -> nothing {
    if ($flake | str starts-with 'path:') {
        print '  ⚠ path: 会把整个目录（含 untracked/ignored/.git）拷入 world-readable nix store'
        print '     → 优先 git add/commit；不要把 path: 当作绕过脏工作区的默认手段'
        return
    }
    let remote = (
        [
            'github:'
            'git+'
            'https:'
            'http:'
            'tarball+'
            'flake:'
        ]
        | any {|p| $flake | str starts-with $p }
    )
    if $remote {
        return
    }
    let flake_path = $flake | split row '#' | first
    let dir = if ($flake_path | is-empty) or ($flake_path == '.') { '.' } else { $flake_path }
    let repo_res = (^git -C $dir rev-parse --show-toplevel | complete)
    if $repo_res.exit_code != 0 {
        return
    }
    let repo = $repo_res.stdout | str trim
    let dirty_res = (^git -C $repo status --porcelain | complete)
    if ($dirty_res.stdout | str trim | is-not-empty) {
        print '  ⚠ 工作区有未提交改动；untracked 文件对 nixos-anywhere 不可见'
        print '     → 最稳妥：先 commit；不要用 path: 绕过（会泄露 untracked/ignored/.git）'
    }
}

# flake attr 可评估性：提前暴露 host 未注册/配置错误
def check-flake-attr [flake: string]: nothing -> nothing {
    let parts = $flake | split row '#'
    if ($parts | length) < 2 {
        return
    }
    let flake_ref = $parts | first
    let attr = $parts | last
    let expr = (
        $flake_ref + '#nixosConfigurations.' + $attr + '.config.system.build.toplevel.drvPath'
    )
    let res = (^nix eval --impure --raw $expr | complete)
    if $res.exit_code != 0 {
        print ($res.stderr | str trim)
        error make {msg: $'无法 eval ($expr)；先修 flake/host 配置'}
    }
    print $'  ✓ flake attr: ($attr)'
}

# age key：存在性 + 公钥是否是 secrets 的 recipient（不实际解密；sops -d 会回退到默认 key，不可靠）
def check-age-key [age_key: string]: nothing -> nothing {
    if ($age_key | str trim | is-empty) {
        print '  · 未指定 --age-key（目标需要用户 sops secrets 时请注入）'
        return
    }
    let key_path = $age_key | path expand
    if not ($key_path | path exists) {
        error make {msg: $'age key 不存在: ($key_path)'}
    }
    print $'  ✓ age key: ($key_path)'
    if (which age-keygen | length) == 0 {
        print '  · 未安装 age-keygen，跳过 recipient 校验'
        return
    }
    let secrets_file = 'secrets/secrets.yaml'
    if not ($secrets_file | path exists) {
        return
    }
    let pub_res = (^age-keygen -y $key_path | complete)
    if $pub_res.exit_code != 0 {
        print '  ⚠ 无法从 age key 推导公钥；确认文件格式'
        return
    }
    let pubkey = $pub_res.stdout | str trim
    let rec_res = (^grep -o 'age1[a-z0-9]*' $secrets_file | complete)
    if $rec_res.exit_code != 0 {
        print '  ⚠ secrets/secrets.yaml 中没找到 age recipient'
        return
    }
    let recipients = (
        $rec_res.stdout
        | lines
        | sort
        | uniq
    )
    if ($recipients | any {|r| $r == $pubkey }) {
        print '  ✓ age key recipient 匹配 secrets/secrets.yaml'
    } else {
        print $'  ⚠ age key 公钥 ($pubkey) 不在 secrets/secrets.yaml 的 recipient 中'
    }
}

# 把 age key staging 到 /tmp，返回注入参数；未指定则返回空列表
def stage-age-key [age_key: string]: nothing -> record {
    if ($age_key | str trim | is-empty) {
        return {
            dir: ''
            extra_args: []
        }
    }
    let key_path = $age_key | path expand
    let dir = (^mktemp -d '/tmp/nixos-anywhere-age.XXXXXX' | str trim)
    let age_dir = $dir | path join 'home' 'luck' '.config' 'sops' 'age'
    try {
        mkdir $age_dir
        cp $key_path ($age_dir | path join 'keys.txt')
        ^chmod 700 $age_dir
        ^chmod 600 ($age_dir | path join 'keys.txt')
    } catch {|err|
        rm -rf $dir
        error make {msg: $'age key staging 失败: ($err.msg)'}
    }
    print $'◆ age key: ($key_path) → home/luck/.config/sops/age/keys.txt'
    print ''
    {
        dir: $dir
        extra_args: ['--extra-files', $dir, '--chown', 'home/luck', '1000:100']
    }
}

# 清理 age key staging（正常/异常路径的兜底；shell trap 覆盖 INT/TERM）
def cleanup-stage [dir: path]: nothing -> nothing {
    if ($dir | str trim | is-not-empty) {
        try { rm -rf $dir } catch {|_| null }
    }
}

# 远端环境检查：单次 SSH 连接执行全部检查
#
# 远端用 POSIX sh（set -e）依次执行:
#   1. SSH 连通性
#   2. uname -s = Linux
#   3. 架构（与目标 host 的 system 对齐）
#   4. setsid --wait（避免 BusyBox 版 setsid 无 --wait 导致 kexec 失败）
#   5. kexec_load_disabled（确认 kexec 未被内核禁用）
#   6. passwordless sudo（避免 nixos-anywhere 多次要密码）
#   7. 目标盘存在（test -b）+ 型号/序列号（人工核对 disko.nix）
#   8. 内存 / 虚拟化（closure 门禁和排查用）
#
# SSH 直接输出到终端；不要 pipe（如 | complete），否则 SSH 无法访问 /dev/tty 读密码。
def check-remote [host: string, disk: string]: nothing -> bool {
    let script = '
set -e
echo "  [1/8] SSH 连通性... OK"
echo "  [2/8] 操作系统..."
uname -s
test "$(uname -s)" = Linux
echo "  [3/8] 架构..."
uname -m
echo "  [4/8] setsid --wait..."
setsid --help 2>&1 | grep -q -- --wait
echo "  [5/8] kexec..."
if [ -r /proc/sys/kernel/kexec_load_disabled ]; then
    test "$(cat /proc/sys/kernel/kexec_load_disabled)" != 1
fi
echo "  [6/8] passwordless sudo..."
if [ "$(id -u)" = 0 ]; then
    echo "    root 登录，跳过"
elif command -v sudo >/dev/null 2>&1 && sudo -n true; then
    echo "    OK"
else
    echo "    缺少 passwordless sudo（nixos-anywhere 会多次要密码）"
    exit 1
fi
echo "  [7/8] 目标盘 ' + $disk + '..."
if [ ! -b ' + $disk + ' ]; then
    echo "    目标盘不存在或不是块设备: ' + $disk + '"
    exit 1
fi
lsblk -dno NAME,SIZE,TYPE,MODEL,SERIAL ' + $disk + ' | sed "s/^/    /" || true
echo "  [8/8] 内存/虚拟化..."
free -m | sed -n "1,2p" || true
systemd-detect-virt || true
echo ""
echo "✓ 远端 preflight 全部通过"
'

    try {
        ^ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new $host $script
    } catch {|err|
        error make {msg: $'远端 preflight 失败，请检查目标机状态: ($err.msg)'}
    }

    # key auth 单独探测（BatchMode 不会弹密码）；失败只提示，不阻断
    let auth = (
        ^ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new $host 'true'
        | complete
    )
    if $auth.exit_code != 0 {
        print '  ⚠ key auth 未配置（先 ssh-copy-id）；installer 检查将降级为告警'
        false
    } else {
        print '  ✓ key auth OK'
        true
    }
}
