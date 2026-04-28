{
  config,
  lib,
  pkgs,
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
  };
in {
  options.modules.networking.mihomo = {
    enable = mkEnableOption "mihomo proxy service";
  };

  config = mkIf cfg.enable {
    sops.templates."mihomo-client.json".content = client.templatesContent;

    services.mihomo = {
      enable = true;
      package = pkgs.mihomo;
      configFile = config.sops.templates."mihomo-client.json".path;
      tunMode = true;
    };

    # 和 singbox 一样绑定 systemd-networkd 生命周期，避免 networkd 重启后 TUN 路由丢失
    systemd.services.mihomo = {
      after = ["systemd-networkd.service" "network-online.target"];
      wants = ["network-online.target"];
      partOf = ["systemd-networkd.service"];
      bindsTo = ["systemd-networkd.service"];
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
