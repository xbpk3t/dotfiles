{
  config,
  hostMeta,
  mail,
  pkgs,
  userMeta,
  ...
}:
{
  imports = [ ../_base/nixos-vps ];

  modules = {
    kernel.sysctl.hardware = {
      cpuCores = 5;
      memGiB = 6;
      bwMbps = 800;
      # LA→China 跨境链路 RTT，用于 BDP 计算 socket buffer 上限
      rttMs = 150;
    };

    networking.tailscale = {
      exitNode = true;
      derper = {
        enable = true;
        domain = "derp-nixos-vps-dev.lucc.dev";
        acmeEmail = mail;
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
      # 稳定 UUID：`uuidgen` 生成一次后固定，避免 hostname/FQDN 变化导致重复注册。
      nezha.agent.uuid = "2fe2025b-cc20-4e43-b0dc-d9d24c31fbe4";
    };
  };

  # Nezha state backup: keep the SQLite DB and the dashboard config in a
  # dedicated restic repo under the existing R2 backup bucket. The restic
  # NixOS module provides the systemd timer, encryption, retention and the
  # `restic-nezha` wrapper; no custom timer.
  sops.templates = {
    "restic-nezha-repository".content = "s3:${config.sops.placeholder.CF_R2_ENDPOINT}/agt-backup/nezha";
    "restic-nezha-env".content = ''
      AWS_ACCESS_KEY_ID=${config.sops.placeholder.CF_R2_AK}
      AWS_SECRET_ACCESS_KEY=${config.sops.placeholder.CF_R2_SK}
      AWS_DEFAULT_REGION=auto
    '';
  };

  services.restic.backups.nezha = {
    repositoryFile = config.sops.templates."restic-nezha-repository".path;
    passwordFile = config.sops.secrets.RESTIC_PASSWORD.path;
    environmentFile = config.sops.templates."restic-nezha-env".path;

    # Do not copy a live SQLite file. `.backup` produces a consistent
    # snapshot inside the service's RuntimeDirectory; restic then backs up
    # that copy together with the generated dashboard config.
    backupPrepareCommand = ''
      ${pkgs.sqlite}/bin/sqlite3 /var/lib/nezha/sqlite.db ".backup '/run/restic-backups-nezha/sqlite.db'"
      if [ -f /etc/nezha/config.yaml ]; then
        ${pkgs.coreutils}/bin/cp /etc/nezha/config.yaml /run/restic-backups-nezha/config.yaml
      fi
    '';
    paths = [ "/run/restic-backups-nezha" ];
    backupCleanupCommand = ''
      ${pkgs.coreutils}/bin/rm -f /run/restic-backups-nezha/sqlite.db /run/restic-backups-nezha/config.yaml
    '';

    initialize = true;
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
    pruneOpts = [
      "--keep-hourly 24"
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 3"
    ];
    checkOpts = [ "--read-data-subset=1%" ];
    extraBackupArgs = [ "--tag nezha" ];
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
      services = {
        "9router".endpoints."tcp:80" = "http://127.0.0.1:20228";
        # Tailscale Service svc:nezha is defined in
        # infra/stacks/homelab/tailscale/tailnet (tailscale_service.nezha).
        # URL: http://nezha.tailf19540.ts.net/
        "nezha".endpoints."tcp:80" = "http://127.0.0.1:8008";
      };
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
