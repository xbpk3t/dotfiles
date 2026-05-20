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
    inherit (cfg) wildUrl;
  };
in {
  options.modules.networking.mihomo = {
    enable = mkEnableOption "mihomo TUN proxy daemon";
    wildUrl = mkOption {
      type = lib.types.str;
      description = ''
        Sub-Store wild provider subscription URL 模板。

        URL 中可使用 __ADMIN_PATH__ 占位符，在 sops template 渲染阶段会被
        替换成 config.sops.placeholder.ME_SK 的实值（与 axonhub DEFAULT_SK 同源）。
        admin path 永不进 /nix/store。
      '';
    };
  };

  config = mkIf cfg.enable {
    # sops 渲染含 secret 的 JSON config，不进 /nix/store
    sops.templates."mihomo-client.json".content = client.templatesContent;
    # self provider 也含 secret（uuid / pubkey 等），同样走 sops template
    sops.templates."mihomo-self-provider.json".content = client.selfProviderContent;

    # 单 daemon：启动时将 sops 渲染的两份 JSON 分别转 YAML 落盘，然后 exec mihomo
    # Metacubexd 作为 Web UI 通过 external-controller 端口管理配置
    launchd.daemons.mihomo-tun = {
      serviceConfig = {
        Label = "local.mihomo.tun";
        ProgramArguments = [
          "${pkgs.bash}/bin/bash"
          "-c"
          ''
            src="${config.sops.templates."mihomo-client.json".path}"
            src_self="${config.sops.templates."mihomo-self-provider.json".path}"
            dst="/var/lib/mihomo/config.yaml"
            dst_self="/var/lib/mihomo/providers/self.yaml"
            mkdir -p /var/lib/mihomo/providers
            if [ -f "$src" ]; then
              ${pkgs.yq-go}/bin/yq -P -o yaml <"$src" >"$dst"
            fi
            if [ -f "$src_self" ]; then
              ${pkgs.yq-go}/bin/yq -P -o yaml <"$src_self" >"$dst_self"
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
          SAFE_PATHS = "${pkgs.metacubexd}";
        };
      };
    };
  };
}
