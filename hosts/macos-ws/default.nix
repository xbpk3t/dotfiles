{ userMeta, ... }:
let
  inherit (userMeta) username;
in
{
  modules.networking = {
    # Mihomo (Clash.Meta) proxy service (client)
    # wild 订阅源由 sops 自动发现（SUB_* secrets → sub.<name>），host 无需配置
    mihomo-client.enable = true;
  };

  # https://mynixos.com/nix-darwin/options/launchd
  # 之所以放在这里，因为不同host的launchd本就不同
  #
  # ——— [2026-08-18] 磁盘治理：根权限清理 ———
  # 用户态清理（go-build / docker prune / var/folders / mole cleanup）走 dagu（home/base/AI/dagu/mac.yml，每月）；
  # 这里只放需要 root 的系统内容（nix generations 裁剪）。
  launchd = {
    daemons = {

      # TODO: [2026-09-03] 等 Determinate-Nix 原生支持GC + prune system generations 之后，可以把这个launchd踢掉
      #
      # Determinate Nixd 的 automatic GC 负责 store 级回收，不会自动裁剪旧 system generations。
      # 这里在 Darwin host 层补一条最小化 retention policy；由于 system daemon 本身以 root 运行，
      # 直接执行 nix-collect-garbage 即等价于手动执行 `sudo nix-collect-garbage --delete-older-than 7d`。
      nix-prune-generations = {
        serviceConfig = {
          Label = "local.nix.prune.generations";
          # 注意：nix-collect-garbage 不在 /run/current-system/sw/bin/（system profile），
          # 而在 /nix/var/nix/profiles/default/bin/（nix-daemon default profile）。
          # 用 nix-profile 路径而非 store 路径，避免 GC 后二进制消失。
          ProgramArguments = [
            "/nix/var/nix/profiles/default/bin/nix-collect-garbage"
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
            PATH = "/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          WorkingDirectory = "/Users/${username}";
        };
      };
    };
  };
}
