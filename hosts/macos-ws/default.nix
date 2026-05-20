{userMeta, ...}: let
  username = userMeta.username;
in {
  modules.networking = {
    singbox.enable = false;
    mihomo = {
      enable = true;
      # __ADMIN_PATH__ 在 sops template 渲染时由 sops-nix 自动替换为 ME_SK 实值
      # （与 axonhub compose.yml 复用同一 sops secret，跟 home/core/devops/cntr.nix 同源）。
      # admin path 永不进 /nix/store；本地/生产同一表达式。
      wildUrl = "http://127.0.0.1:3001/__ADMIN_PATH__/download/collection/wild?target=ClashMeta";
    };
  };

  # https://mynixos.com/nix-darwin/options/launchd
  # 之所以放在这里，因为不同host的launchd本就不同
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
          RunAtLoad = true;
          ThrottleInterval = 86400;

          StandardOutPath = "/Users/${username}/Library/Logs/nix-prune-generations.log";
          StandardErrorPath = "/Users/${username}/Library/Logs/nix-prune-generations.log";
          EnvironmentVariables = {
            PATH = "/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
          WorkingDirectory = "/Users/${username}";
        };
      };
    };
  };
}
