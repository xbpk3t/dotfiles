{
  config,
  pkgs,
  lib,
  mylib,
  userMeta,
  ...
}:
with lib; let
  cfg = config.modules.networking.mihomo;
  username = userMeta.username;
  client = import ../../lib/mihomo/client-config.nix {
    inherit
      config
      mylib
      lib
      pkgs
      ;
  };
in {
  options.modules.networking.mihomo = {
    enable = mkEnableOption "mihomo TUN proxy daemon";
  };

  config = mkIf cfg.enable {
    # sops 渲染含 secret 的 JSON config，不进 /nix/store
    sops.templates."mihomo-client.json".content = client.templatesContent;

    # 单 daemon：启动时将 sops 渲染的 JSON 转 YAML，然后 exec mihomo
    # Metacubexd 作为 Web UI 通过 external-controller 端口管理配置
    launchd.daemons.mihomo-tun = {
      serviceConfig = {
        Label = "local.mihomo.tun";
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          ''
            src="${config.sops.templates."mihomo-client.json".path}"
            dst="/var/lib/mihomo/config.yaml"
            mkdir -p /var/lib/mihomo
            if [ -f "$src" ]; then
              ${pkgs.yq-go}/bin/yq -P -o yaml <"$src" >"$dst"
            fi
            exec ${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f "$dst"
          ''
        ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
          NetworkState = true;
        };
        WorkingDirectory = "/var/lib/mihomo";
        StandardOutPath = "/Users/${username}/Library/Logs/mihomo.log";
        StandardErrorPath = "/Users/${username}/Library/Logs/mihomo.log";
        EnvironmentVariables = {
          PATH = "/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        };
      };
    };
  };
}
