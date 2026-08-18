{ userMeta, pkgs, ... }:
let
  inherit (userMeta) username;
in
{
  modules.networking = {
    singbox.enable = false;
    # wild 订阅源由 sops 自动发现（SUB_* secrets → sub.<name>），host 无需配置
    mihomo.enable = true;
  };

  # https://mynixos.com/nix-darwin/options/launchd
  # 之所以放在这里，因为不同host的launchd本就不同
  #
  # ——— [2026-08-18] 磁盘治理：根权限清理 ———
  # 用户态清理（go-build / docker prune / mole cleanup）走 dagu（home/base/AI/dagu/mac.yml，每月）；
  # 这里只放需要 root 的系统内容。脚本用 writeShellScript（bash，闭包自包含、零依赖）。
  # 幂等：目录不存在则跳过。
  launchd = {
    daemons = {
      # Determinate Nixd 的 automatic GC 负责 store 级回收，不会自动裁剪旧 system generations。
      # 这里在 Darwin host 层补一条最小化 retention policy；由于 system daemon 本身以 root 运行，
      # 直接执行 nix-collect-garbage 即等价于手动执行 `sudo nix-collect-garbage --delete-older-than 7d`。
      nix-prune-generations = {
        serviceConfig = {
          Label = "local.nix.prune.generations";
          ProgramArguments = [
            "/run/current-system/sw/bin/nix-collect-garbage"
            "--delete-older-than"
            "7d"
          ];
          StartCalendarInterval = [
            {
              Hour = 3;
              Minute = 10;
            }
          ];
          ThrottleInterval = 86400;
          Nice = 5;

          StandardOutPath = "/Users/${username}/Library/Logs/nix-prune-generations.log";
          StandardErrorPath = "/Users/${username}/Library/Logs/nix-prune-generations.log";
          EnvironmentVariables = {
            PATH = "/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          WorkingDirectory = "/Users/${username}";
        };
      };

      # 每周日凌晨 4:30 清理需要 root 的系统内容（GarageBand/Logic 内容包残留 + 诊断报告 + 用户临时文件）
      # 用 bash（writeShellScript 闭包自包含、零依赖）；nushell 版曾考虑但 unstable 无 writeNuScript，
      # 手动 shebang 不记录 nu 引用有 GC 风险，对 launchd daemon 属过度设计。
      mac-cleanup = {
        serviceConfig = {
          Label = "local.mac.cleanup";
          ProgramArguments = [
            "${pkgs.writeShellScript "mac-cleanup" ''
              # GarageBand/Logic 内容包残留（Apple Loops / 采样库 / 诊断报告），幂等
              for d in "/Library/Audio/Apple Loops" "/Library/Application Support/Logic" /Library/Logs/DiagnosticReports; do
                [ -d "$d" ] && rm -rf "$d"
              done
              # 用户临时目录中 7 天前的文件（不碰运行中进程的；站点沙箱目录会报
              # Operation not permitted，属预期，丢弃即可）
              find /private/var/folders -path "*/T/*" -type f -mtime +7 -delete 2>/dev/null || true
            ''}"
          ];
          StartCalendarInterval = [
            {
              Hour = 4;
              Minute = 30;
            }
          ];
          RunAtLoad = false;
          ThrottleInterval = 86400;
          Nice = 5;

          StandardOutPath = "/Users/${username}/Library/Logs/mac-cleanup.log";
          StandardErrorPath = "/Users/${username}/Library/Logs/mac-cleanup.log";
          EnvironmentVariables = {
            PATH = "/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          WorkingDirectory = "/Users/${username}";
        };
      };
    };
  };
}
