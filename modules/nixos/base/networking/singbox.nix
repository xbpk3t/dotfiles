{config, ...}: let
  cfg = config.services.sing-box;
in {
  #  config = lib.mkIf cfg.enable {
  #
  #  };

  systemd.services.sing-box = {
    description = "Sing-box Proxy Service";
    wantedBy = ["multi-user.target"];
    after = ["network.target"];
    serviceConfig = {
      ExecStart = "${cfg.package}/bin/sing-box run -c /etc/sing-box/config.json";
      Restart = "always";
      DynamicUser = false;
    };
  };
}
