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

    # activation 阶段把渲染后的 JSON 转为 YAML 并拷到 ClashX Pro 的默认路径
    system.activationScripts.mihomoConfig.text = ''
      dst="/Users/${username}/.config/clash"
      src="${config.sops.templates."mihomo-client.json".path}"
      mkdir -p "$dst"
      if [ -f "$src" ]; then
        ${pkgs.yq-go}/bin/yq -P -o yaml <"$src" >"$dst/lucas.yaml"
        chown ${username}:staff "$dst/lucas.yaml"
        chmod 600 "$dst/lucas.yaml"
      else
        echo "[mihomo] sops template not yet rendered at $src — run sops-install-secrets or wait for its LaunchAgent" >&2
      fi
    '';
  };
}
