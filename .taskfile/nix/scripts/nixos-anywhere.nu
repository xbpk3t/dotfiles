#!/usr/bin/env nu

# nixos-anywhere 远程刷机脚本
#
# 设计要点:
#   - 所有远端 preflight 在 *单次 SSH 连接* 中完成 → 只输一次密码
#   - 默认 dry-run（只打印），加 --execute 才真正执行
#   - 本地已有 nixos-anywhere 则直接调用，否则用 nix run 回退
#
# 用法:
#   nu .taskfile/nix/scripts/nixos-anywhere.nu --flake "path#host" --host "root@ip"
#   nu .taskfile/nix/scripts/nixos-anywhere.nu --flake "path#host" --host "root@ip" --execute

export def main [
    --flake: string                     # flake 引用（path#nixosConfigurationName）
    --host: string                      # 目标 SSH（root@ip）
    # Why 不加 --no-reboot：ssh public key 已写入 NixOS config，
    # 刷机后直接 reboot 即可 key auth 登录，无需手动传 key。
    --na-args: string = "--debug"  # 透传给 nixos-anywhere 的额外参数
    --execute                           # 设此标志则真正执行，否则 dry-run
]: nothing -> nothing {

    print $'■ nixos-anywhere: FLAKE=($flake) HOST=($host)'
    print ''

    # ── [1/3] 本地 preflight ──────────────────────────
    print '◆ [1/3] 本地环境检查'
    check-local $flake $host
    print '  ✓ 全部通过'
    print ''

    # ── [2/3] 远端 preflight（单次 SSH）───────────────
    print '◆ [2/3] 远端环境检查'
    check-remote $host
    print ''

    # ── [3/3] 执行 ──────────────────────────────────
    print '◆ [3/3] nixos-anywhere 命令'

    let has_na = (which nixos-anywhere | length) > 0
    let cmd_display = if $has_na {
        $'  nixos-anywhere --flake ($flake) --target-host ($host) ($na_args)'
    } else {
        $'  nix run --refresh github:nix-community/nixos-anywhere -- --flake ($flake) --target-host ($host) ($na_args)'
    }

    print '  ──────────────────────────────────────────────'
    print $cmd_display
    print '  ──────────────────────────────────────────────'

    if not $execute {
        print ''
        print '⚠ DRY-RUN: 加 --execute 以真正执行'
        return
    }

    print ''
    print '◆ 开始执行...'

    let args = ["--flake", $flake, "--target-host", $host, ...($na_args | split row ' ')]

    if $has_na {
        ^nixos-anywhere ...$args
    } else {
        ^nix run --refresh github:nix-community/nixos-anywhere -- ...$args
    }

    if $env.LAST_EXIT_CODE != 0 {
        error make { msg: $'nixos-anywhere 执行失败 (exit: $env.LAST_EXIT_CODE)' }
    }

    print '✓ 完成'
}


# ═══════════════  helpers  ═══════════════

# 本地环境检查：flake/host 格式、ssh/nix 命令是否存在
def check-local [flake: string, host: string]: nothing -> nothing {
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
}

# 远端环境检查：单次 SSH 连接执行全部检查
#
# 远端用 POSIX sh（set -e）依次执行:
#   1. SSH 连通性（能连上就算过）
#   2. uname -s = Linux（kexec 前提）
#   3. setsid --wait（避免 BusyBox 版 setsid 无 --wait 导致 kexec 失败）
#   4. kexec_load_disabled（确认 kexec 未被内核禁用）
#
# 使用 | complete 捕获 stdout 而非直接终端输出，以便在失败时打印已通过的检查项。
# SSH 密码提示走 /dev/tty 不受 stdout 管道影响。
def check-remote [host: string]: nothing -> nothing {
    let script = '
set -e
echo "  [1/4] SSH 连通性... OK"
echo "  [2/4] 操作系统... $(uname -s)"
test "$(uname -s)" = Linux
echo "  [3/4] setsid --wait... OK"
setsid --help 2>&1 | grep -q -- --wait
echo "  [4/4] kexec 可用... OK"
if [ -r /proc/sys/kernel/kexec_load_disabled ]; then
    test "$(cat /proc/sys/kernel/kexec_load_disabled)" != 1
fi
echo ""
echo "✓ 远端 preflight 全部通过"
'

    # 注意：不能 pipe（| complete 等），否则 SSH 无法访问 /dev/tty
    # 读密码，所有认证都会以 "Device not configured" 失败。
    ^ssh -o ConnectTimeout=5 $host $script

    if $env.LAST_EXIT_CODE != 0 {
        error make { msg: '远端 preflight 失败，请检查目标机状态' }
    }
}
