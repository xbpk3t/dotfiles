{
  config,
  lib,
  pkgs,
  myvars,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  client = import ../../../lib/singbox/client-config.nix {
    inherit
      config
      myvars
      mylib
      lib
      pkgs
      ;
  };
in {
  # https://mynixos.com/nixpkgs/options/services.sing-box

  # 只有desktop才需要引入singbox（因为所有VPS默认本身都不需要挂singbox），所以放在这里
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box proxy service";
  };

  config = mkIf cfg.enable {
    # systemctl status sing-box.service
    # sudo journalctl -u sing-box -n 50 --no-pager
    services.sing-box = {
      enable = true;
      settings = client.configJson;
    };

    # Q: Why add extra systemd deps if services.sing-box already creates the unit?
    # A: The upstream module doesn't bind sing-box to systemd-networkd. When
    #    networkd restarts (e.g. during colmena apply), the TUN link/routes can
    #    be reset while sing-box keeps running, causing "service alive but no
    #    traffic" (e.g. TLS EOF to cache.nixos.org). We bind the lifecycle so
    #    sing-box restarts and re-injects routes after networkd restarts.
    #
    # Q: Isn't After=network-online.target enough?
    # A: After/Wants only affect start order, not restart coupling. Without
    #    PartOf/BindsTo, a networkd restart won't restart sing-box.
    #
    # Q: Why not change the upstream module?
    # A: Keep a local drop-in here to avoid forking; adjust if upstream adds this.
    #
    # Ref:
    # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/networking/sing-box.nix
    #
    # github.com/NixOS/nixpkgs/blob/master/nixos/tests/sing-box.nix/
    #
    # 以上这些问题都可以通过查看以上源码中，有所体现
    systemd.services.sing-box = {
      after = ["systemd-networkd.service" "network-online.target"];
      wants = ["network-online.target"];
      partOf = ["systemd-networkd.service"];
      bindsTo = ["systemd-networkd.service"];
    };
  };
}
