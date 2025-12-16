{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.netbird;
in {
  # https://github.com/nukdokplex/ncaa/blob/master/nixos-modules/netbird-client.nix
  options.modules.networking.netbird = {
    enable = mkEnableOption "NetBird client (VPN mesh network) on this host";
  };

  config = mkIf cfg.enable {
    # Use native NixOS netbird service with "default" key
    # This creates: netbird-default.service, socket at /var/run/netbird-default/sock
    services.netbird.clients.default = {
      autoStart = true;
      openFirewall = true;
      logLevel = "info";

      # Keep SSH on system side; disable NetBird firewall/ssh handling.
      config = {
        # 禁用 Netbird 内置 SSH
        ServerSSHAllowed = false;
        # 禁用 Netbird 内置 firewall
        DisableFirewall = true;
      };
    };

    # Add netbird CLI and nftables to system packages
    environment.systemPackages = [
      pkgs.netbird
      pkgs.nftables
    ];

    # CLI socket compatibility symlinks/tmpfiles
    systemd.tmpfiles.rules = [
      "d /var/run/netbird 0755 root root -"
      "L+ /var/run/netbird/sock - - - - /var/run/netbird-default/sock"
      "d /var/run/netbird-default 0755 netbird-default netbird-default -"
    ];
  };
}
