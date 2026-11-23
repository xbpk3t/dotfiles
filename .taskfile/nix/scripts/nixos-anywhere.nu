#!/usr/bin/env nu

# nixos-anywhere 远程刷机脚本
#
# 设计要点:
#   - 默认 dry-run：只做本地/远端 preflight 并打印命令，不 staging、不安装
#   - 主 preflight 在 *单次 SSH 连接* 中完成 → 只输一次密码；key-auth 用 BatchMode 单独探测
#   - age key 只在 --execute 时 staging；/tmp 下 700 目录 + 600 文件，shell trap 保证 Ctrl-C 也清理
#   - 本地已有 nixos-anywhere 则直接调用，否则用 nix run 回退（--refresh 不锁版本）
#
# 用法:
#   nu .taskfile/nix/scripts/nixos-anywhere.nu --flake "path#host" --host "root@ip" --disk /dev/vda
#   nu .taskfile/nix/scripts/nixos-anywhere.nu --flake "path#host" --host "root@ip" --execute
#   nu .taskfile/nix/scripts/nixos-anywhere.nu --flake "path#host" --host "root@ip" \
#     --age-key "$HOME/Library/Application Support/sops/age/keys.txt" --execute
#
# NA_ARGS 按空格拆分；值里含空格/引号时无法可靠传参，请避免。

def main [
    --flake: string = ''                # flake 引用（<flakeref>#<NODE>）
    --host: string = ''                 # 目标 SSH（root@ip）
    # Why 加 --option pure-eval false：仓库依赖 impure eval（未 track 源码目录），
    # nixos-anywhere 没有 --impure，但可以把该选项透传给内部 nix。
    --na-args: string = '--debug --option pure-eval false'  # 透传给 nixos-anywhere 的额外参数（按空格拆分）
    --age-key: string = ''              # 可选：age key 路径；注入 home/luck/.config/sops/age/keys.txt
    --disk: string = '/dev/vda'         # 目标盘；必须与目标 host 的 disko.nix 一致
    --execute                           # 设此标志则真正执行，否则 dry-run
]: nothing -> nothing {

    # ── [1/3] 本地 preflight ──────────────────────────
    print '◆ [1/3] 本地环境检查'
    check-local $flake $host $na_args $age_key $disk
    print '  ✓ 全部通过'
    print ''

    print $'■ nixos-anywhere: FLAKE=($flake) HOST=($host) DISK=($disk)'
    print ''
    print ''

    # ── [2/3] 远端 preflight（单次 SSH）───────────────
    print '◆ [2/3] 远端环境检查'
    check-remote $host $disk
    print ''

    # ── [3/3] 执行 ──────────────────────────────────
    print '◆ [3/3] nixos-anywhere 命令'

    let has_na = (which nixos-anywhere | length) > 0
    let has_age_key = ($age_key | str trim | is-not-empty)
    let display_args = if $has_age_key {
        $na_args + ' --extra-files <age-key-stage> --chown home/luck 1000:100'
    } else {
        $na_args
    }
    let cmd_display = if $has_na {
        $'  nixos-anywhere --flake ($flake) --target-host ($host) ($display_args)'
    } else {
        $'  nix run --refresh github:nix-community/nixos-anywhere -- --flake ($flake) --target-host ($host) ($display_args)'
    }

    print '  ──────────────────────────────────────────────'
    print $cmd_display
    print '  ──────────────────────────────────────────────'

    if not $execute {
        print ''
        print '⚠ DRY-RUN: 未 staging age key、未执行安装；加 --execute 以真正执行'
        return
    }

    # execute 前最后一道本地门禁：host 必须可 eval（dry-run 不跑，避免慢 eval）
    check-flake-attr $flake

    # ── age key staging（仅 --execute）───────────────
    let staged = (stage-age-key $age_key)
    let stage_dir = $staged.dir
    let extra_args = $staged.extra_args

    print ''
    print '◆ 开始执行...'

    let args = [...["--flake", $flake, "--target-host", $host] ...($na_args | split row ' ' | where {|x| $x | is-not-empty}) ...$extra_args]
    let runner = if $has_na {
        ["nixos-anywhere"]
    } else {
        ["nix", "run", "--refresh", "github:nix-community/nixos-anywhere", "--"]
    }

    try {
        if ($stage_dir | is-not-empty) {
            # shell trap：正常退出、INT、TERM 都清理明文 key
            let trap_script = '
cleanup() { s=$?; trap - EXIT INT TERM; rm -rf "$STAGE_DIR"; exit $s; }
trap cleanup EXIT
trap "exit 130" INT
trap "exit 143" TERM
"$@"
'
            with-env { STAGE_DIR: $stage_dir } { ^sh -c $trap_script _ ...$runner ...$args }
        } else {
            with-env { STAGE_DIR: '' } { ^sh -c '"$@"' _ ...$runner ...$args }
        }
    } catch {|err|
        cleanup-stage $stage_dir
        error make { msg: $'nixos-anywhere 执行失败: ($err.msg)' }
    }

    cleanup-stage $stage_dir
    print '✓ 完成'
    print ''
    print '后续（首启验收）:'
    print $'  1. ssh-keygen -R ($host | split row "@" | last) 或 StrictHostKeyChecking=accept-new'
    print '  2. 检查 hostname / id / linger / sops / sshd / firewall / virtio / fstab / disk'
    print '  3. 若未用 --chown 注入：chown -R luck:users /home/luck 后再 deploy'
    print '  4. 若用了 --phases 未 reboot：先在 installer 检查 /mnt/boot/initrd 含 virtio'
}


# ═══════════════  helpers  ═══════════════

# 本地环境检查：格式、flake 可见性、age key、disk
def check-local [
    flake: string
    host: string
    na_args: string
    age_key: string
    disk: string
]: nothing -> nothing {
    if ($flake | str trim | is-empty) {
        error make { msg: '缺少 FLAKE（例：./dotfiles#nixos-vps）' }
    }
    if not ('#' in $flake) {
        error make { msg: 'FLAKE 必须包含 #（例：./dotfiles#my-host）' }
    }
    if ($host | str trim | is-empty) {
        error make { msg: '缺少 HOST（例：root@1.2.3.4）' }
    }
    if (which ssh | length) == 0 {
        error make { msg: '本地缺少 ssh' }
    }
    if (which nix | length) == 0 {
        error make { msg: '本地缺少 nix（用于回退: nix run）' }
    }
    if ($na_args | str contains '--flake') or ($na_args | str contains '--target-host') {
        error make { msg: 'NA_ARGS 不能包含 --flake/--target-host；用 FLAKE/HOST 指定目标' }
    }
    if ($age_key | str trim | is-not-empty) and ($na_args | str contains '--extra-files') {
        error make { msg: 'NA_ARGS 已包含 --extra-files；请把 age key 放进该目录，或去掉 --age-key' }
    }
    if not ($disk =~ '^/dev/[A-Za-z0-9/_.:-]+$') {
        error make { msg: $'DISK 格式不合法: ($disk)' }
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
    let remote = (['github:' 'git+' 'https:' 'http:' 'tarball+' 'flake:'] | any {|p| $flake | str starts-with $p })
    if $remote {
        return
    }
    let flake_path = ($flake | split row '#' | first)
    let dir = if ($flake_path | is-empty) or ($flake_path == '.') { '.' } else { $flake_path }
    let repo_res = (^git -C $dir rev-parse --show-toplevel | complete)
    if $repo_res.exit_code != 0 {
        return
    }
    let repo = ($repo_res.stdout | str trim)
    let dirty_res = (^git -C $repo status --porcelain | complete)
    if ($dirty_res.stdout | str trim | is-not-empty) {
        print '  ⚠ 工作区有未提交改动；untracked 文件对 nixos-anywhere 不可见'
        print '     → 最稳妥：先 commit；不要用 path: 绕过（会泄露 untracked/ignored/.git）'
    }
}

# flake attr 可评估性：提前暴露 host 未注册/配置错误
def check-flake-attr [flake: string]: nothing -> nothing {
    let parts = ($flake | split row '#')
    if ($parts | length) < 2 {
        return
    }
    let flake_ref = ($parts | first)
    let attr = ($parts | last)
    let expr = ($flake_ref + '#nixosConfigurations.' + $attr + '.config.system.build.toplevel.drvPath')
    let res = (^nix eval --impure --raw $expr | complete)
    if $res.exit_code != 0 {
        print ($res.stderr | str trim)
        error make { msg: $'无法 eval ($expr)；先修 flake/host 配置' }
    }
    print $'  ✓ flake attr: ($attr)'
}

# age key：存在性 + 公钥是否是 secrets 的 recipient（不实际解密；sops -d 会回退到默认 key，不可靠）
def check-age-key [age_key: string]: nothing -> nothing {
    if ($age_key | str trim | is-empty) {
        print '  · 未指定 --age-key（目标需要用户 sops secrets 时请注入）'
        return
    }
    let key_path = ($age_key | path expand)
    if not ($key_path | path exists) {
        error make { msg: $'age key 不存在: ($key_path)' }
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
    let pubkey = ($pub_res.stdout | str trim)
    let rec_res = (^grep -o 'age1[a-z0-9]*' $secrets_file | complete)
    if $rec_res.exit_code != 0 {
        print '  ⚠ secrets/secrets.yaml 中没找到 age recipient'
        return
    }
    let recipients = ($rec_res.stdout | lines | sort | uniq)
    if ($recipients | any {|r| $r == $pubkey }) {
        print '  ✓ age key recipient 匹配 secrets/secrets.yaml'
    } else {
        print $'  ⚠ age key 公钥 ($pubkey) 不在 secrets/secrets.yaml 的 recipient 中'
    }
}

# 把 age key staging 到 /tmp，返回注入参数；未指定则返回空列表
def stage-age-key [age_key: string]: nothing -> record {
    if ($age_key | str trim | is-empty) {
        return { dir: '', extra_args: [] }
    }
    let key_path = ($age_key | path expand)
    let dir = (^mktemp -d '/tmp/nixos-anywhere-age.XXXXXX' | str trim)
    let age_dir = ($dir | path join 'home' 'luck' '.config' 'sops' 'age')
    try {
        mkdir $age_dir
        cp $key_path ($age_dir | path join 'keys.txt')
        ^chmod 700 $age_dir
        ^chmod 600 ($age_dir | path join 'keys.txt')
    } catch {|err|
        rm -rf $dir
        error make { msg: $'age key staging 失败: ($err.msg)' }
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
def check-remote [host: string, disk: string]: nothing -> nothing {
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
        error make { msg: $'远端 preflight 失败，请检查目标机状态: ($err.msg)' }
    }

    # key auth 单独探测（BatchMode 不会弹密码）；失败只提示，不阻断
    let auth = (^ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new $host 'true' | complete)
    if $auth.exit_code != 0 {
        print '  ⚠ key auth 未配置（先 ssh-copy-id）；nixos-anywhere 可能会多次要密码'
    } else {
        print '  ✓ key auth OK'
    }
}
