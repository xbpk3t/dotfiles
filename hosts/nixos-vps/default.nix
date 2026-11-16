{
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

    infra.singbox-server.enable = true;
  };

  services.cron = {
    enable = true;
    mailto = "";
    systemCronJobs = [
      "0 3 * * * ${userMeta.username} nu /home/${userMeta.username}/.cntr/backup-pgsql.nu axonhub"
    ];
  };
}
