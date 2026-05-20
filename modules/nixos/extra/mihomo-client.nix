{
  config,
  pkgs,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.networking.mihomo;
  client = import ../../../lib/mihomo/client-config.nix {
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
    enable = mkEnableOption "mihomo proxy service";
    wildUrl = mkOption {
      type = lib.types.str;
      description = ''
        Sub-Store wild provider subscription URL. 与 darwin 模块同义。
      '';
    };
  };

  config = mkIf cfg.enable {
    sops.templates."mihomo-client.json".content = client.templatesContent;
    sops.templates."mihomo-self-provider.json".content = client.selfProviderContent;

    services.mihomo = {
      enable = true;
      package = pkgs.mihomo;
      configFile = config.sops.templates."mihomo-client.json".path;
      tunMode = true;
    };

    # 把 self provider 同步到 mihomo 的 working dir，由 ExecStartPre 完成 JSON→YAML 转换。
    # services.mihomo 默认 WorkingDirectory 是 /var/lib/mihomo
    systemd.services.mihomo = {
      after = ["systemd-networkd.service" "network-online.target"];
      wants = ["network-online.target"];
      partOf = ["systemd-networkd.service"];
      bindsTo = ["systemd-networkd.service"];
      serviceConfig = {
        # mihomo 默认只允许 homedir 和 SAFE_PATHS 下的路径作为 external-ui
        Environment = "SAFE_PATHS=${pkgs.metacubexd}";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /var/lib/mihomo/providers"
          ''
            ${pkgs.bash}/bin/bash -c '${pkgs.yq-go}/bin/yq -P -o yaml <${config.sops.templates."mihomo-self-provider.json".path} >/var/lib/mihomo/providers/self.yaml'
          ''
        ];
      };
    };

    # DNS 防污染
    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNS = ["1.1.1.1" "8.8.8.8"];
        DNSOverTLS = "yes";
        FallbackDNS = mkDefault config.networking.nameservers;
      };
    };
  };
}
