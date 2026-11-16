{
  config,
  hostMeta,
  userMeta,
  ...
}:
{
  imports = [ ../_base/nixos-vps ];

  modules = {
    networking.tailscale = {
      exitNode = true;
      derper = {
        enable = true;
        domain = hostMeta.tailscale.derpDomain;
        inherit (hostMeta) acmeEmail;
      };
    };

    infra = {
      singbox-server.enable = true;
      healthchecks = {
        enable = true;
        urlFile = config.sops.secrets.HEALTHCHECKS_VPS_DEV.path;
        # If the dashboard is down while the host is up, ping /fail so
        # Healthchecks alerts instead of reporting a healthy host.
        healthUrl = "http://127.0.0.1:8008/";
      };
    };
  };

  services = {
    # 9router dashboard on the tailnet:
    #   Tailscale Service svc:9router is defined in
    #   infra/stacks/homelab/tailscale/tailnet (tailscale_service.ninerouter).
    #   This host advertises tcp:80 -> http://127.0.0.1:20228, so the URL is
    #   http://9router.tailf19540.ts.net/
    #   Note: the current NixOS module emits HTTP (no TLS termination) for
    #   Service endpoints (nixpkgs#530174).
    tailscale.serve = {
      enable = true;
      services."9router".endpoints."tcp:80" = "http://127.0.0.1:20228";
    };

    cron = {
      enable = true;
      mailto = "";
      systemCronJobs = [
        "0 3 * * * ${userMeta.username} nu /home/${userMeta.username}/.cntr/backup-pgsql.nu axonhub"
      ];
    };
  };
}
