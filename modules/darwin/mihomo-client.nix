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
    enable = mkEnableOption "mihomo proxy config for ClashX Pro";
  };

  config = mkIf cfg.enable {
    # sops 渲染含 secret 的 JSON config，不进 /nix/store
    sops.templates."mihomo-client.json".content = client.templatesContent;

    # launchd daemon：每次加载时把 sops 渲染的 JSON 转为 YAML，输出到 ClashX Pro 的配置目录
    launchd.daemons.mihomo-config = {
      serviceConfig = {
        Label = "local.mihomo.config";
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          ''
            src="${config.sops.templates."mihomo-client.json".path}"
            dst="/Users/${username}/.config/clash/lucas.yaml"
            mkdir -p "$(dirname "$dst")"
            if [ -f "$src" ]; then
              ${pkgs.yq-go}/bin/yq -P -o yaml <"$src" >"$dst"
              chown ${username}:staff "$dst"
              chmod 600 "$dst"
            else
              echo "[mihomo] sops template not yet rendered at $src" >&2
              exit 1
            fi
          ''
        ];
        RunAtLoad = true;
        StandardOutPath = "/Users/${username}/Library/Logs/mihomo-config.log";
        StandardErrorPath = "/Users/${username}/Library/Logs/mihomo-config.log";
      };
    };
  };
}
