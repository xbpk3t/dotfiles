{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.networking.tailscale;
in {
  options.modules.networking.tailscale = {
    enable = mkEnableOption "Tailscale client (WireGuard-based mesh VPN) on this host";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.tailscale
    ];

    # https://mynixos.com/nixpkgs/options/services.tailscale
    services.tailscale = {
      enable = true;
      package = pkgs.tailscale;
      # Keep it as a regular client; enables subnet/exit-node routing only when needed.
      useRoutingFeatures = "client";
      openFirewall = true;
    };

    environment.shellAliases = {
      tss = "tailscale";
    };
  };
}
