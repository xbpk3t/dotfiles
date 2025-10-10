{ config, pkgs, lib, ... }:

let
  cfg = config.modules.networking.singbox;
in {
  options.modules.networking.singbox = {
    enable = lib.mkEnableOption "sing-box service";
  };

  config = lib.mkIf cfg.enable {
    # Enable sing-box service on NixOS
    services.sing-box = {
      enable = true;
    };

    # Customize systemd service for sing-box
    # FIXME 替换为直接从 sub-store la qu
    systemd.services.sing-box = {
      description = "Sing-box Proxy Service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /etc/sing-box/config.json";
        Restart = "always";
        DynamicUser = false;
      };
    };

    # Ensure the configuration file is present
    environment.etc."sing-box/config.json" = {
      source = ./config.json; # Replace with the path to your config.json
    };
  };
}