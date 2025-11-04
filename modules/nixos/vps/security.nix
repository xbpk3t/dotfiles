{
  config,
  lib,
  myvars,
  pkgs,
  ...
}: let
  cfg = config.services.vpsSecurity;
  inherit (lib) mkEnableOption mkIf mkDefault mkForce;
  authorizedKeys =
    myvars.mainSshAuthorizedKeys or []
    ++ (myvars.secondaryAuthorizedKeys or []);
in {
  options.services.vpsSecurity.enable =
    mkEnableOption "VPS-focused security hardening (SSH, fail2ban, auditing)"
    // {
      default = true;
    };

  config = mkIf cfg.enable {
    users = {
      mutableUsers = mkDefault false;
      users.root.openssh.authorizedKeys.keys = authorizedKeys;
    };

    services.openssh = {
      enable = true;
      openFirewall = true;
      settings = {
        PasswordAuthentication = mkForce false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = mkForce "without-password";
        X11Forwarding = mkForce false;
        AllowAgentForwarding = mkDefault false;
        ClientAliveInterval = mkDefault 60;
        ClientAliveCountMax = mkDefault 3;
        UseDns = false;
        Compression = mkForce false;
        PubkeyAuthentication = true;
        AllowTcpForwarding = mkForce false;
      };
    };

    services.fail2ban = {
      enable = true;
      package = pkgs.fail2ban;
      maxretry = 3;
      bantime = "1h";
      ignoreIP = [
        "127.0.0.1/8"
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];
      jails = {
        DEFAULT.settings = {
          findtime = "15m";
        };

        sshd = {
          enabled = true;
          settings = {
            port = "ssh";
            maxretry = 3;
            bantime = "1h";
            backend = "systemd";
          };
        };
      };

      /*
      # 以下保持注释，按需解除注释即可恢复完整的入侵防御与杀毒配置
      clamav = {
        daemon = {
          enable = true;
          settings = {
            LogFile = "/var/log/clamav/clamd.log";
            LogTime = true;
            LogClean = false;
            LogSyslog = false;
            LogFacility = "LOG_LOCAL6";
            LogVerbose = false;
            LogRotate = true;
            DatabaseDirectory = "/var/lib/clamav";
            MaxScanSize = "100M";
            MaxFileSize = "25M";
            MaxRecursion = 16;
            MaxFiles = 10000;
            MaxEmbeddedPE = "10M";
            MaxHTMLNormalize = "10M";
            MaxHTMLNoTags = "2M";
            MaxScriptNormalize = "5M";
            MaxZipTypeRcg = "1M";
            MaxThreads = 12;
            ReadTimeout = 180;
            CommandReadTimeout = 5;
            SendBufTimeout = 200;
            MaxQueue = 100;
            IdleTimeout = 30;
            SelfCheck = 3600;
            User = "clamav";
            AllowSupplementaryGroups = true;
            TCPSocket = 3310;
            TCPAddr = "127.0.0.1";
            ExcludePath = [
              "^/proc/"
              "^/sys/"
              "^/dev/"
              "^/run/"
              "^/tmp/"
              "^/var/tmp/"
            ];
          };
        };

        updater = {
          enable = true;
          frequency = 6;
          settings = {
            UpdateLogFile = "/var/log/clamav/freshclam.log";
            LogVerbose = false;
            LogSyslog = false;
            LogFacility = "LOG_LOCAL6";
            LogFileMaxSize = "2M";
            LogRotate = true;
            LogTime = true;
            DatabaseDirectory = "/var/lib/clamav";
            DatabaseOwner = "clamav";
            DNSDatabaseInfo = "current.cvd.clamav.net";
            DatabaseMirror = [
              "db.local.clamav.net"
              "database.clamav.net"
            ];
            MaxAttempts = 5;
            ConnectTimeout = 30;
            ReceiveTimeout = 30;
            NotifyClamd = "/etc/clamav/clamd.conf";
            Checks = 24;
          };
        };
      };

      logrotate = {
        enable = true;
        settings = {
          "/var/log/fail2ban.log" = {
            frequency = "weekly";
            rotate = 4;
            compress = true;
            delaycompress = true;
            missingok = true;
            notifempty = true;
            create = "640 root adm";
            postrotate = "systemctl reload fail2ban || true";
          };

          "/var/log/clamav/*.log" = {
            frequency = "weekly";
            rotate = 4;
            compress = true;
            delaycompress = true;
            missingok = true;
            notifempty = true;
            create = "640 clamav clamav";
            postrotate = "systemctl reload clamav-daemon || true";
          };
        };
      };
      */
    };

    security = {
      auditd.enable = mkDefault false;
      pam.loginLimits = [
        {
          domain = "*";
          type = "hard";
          item = "core";
          value = "0";
        }
      ];
      sudo.wheelNeedsPassword = mkDefault true;
    };

    networking.firewall = {
      enable = lib.mkForce true;
      allowedTCPPorts = mkDefault [22];
      logRefusedConnections = mkDefault true;
    };

    /*
    # 原先额外的系统加固参数，可按需恢复
    environment.systemPackages = with pkgs; [
      fail2ban
      clamav
      lynis
      rkhunter
      chkrootkit
      aide
      logwatch
      psad
    ];

    security = {
      apparmor.enable = lib.mkDefault true;
      forcePageTableIsolation = true;
      kernel.sysctl = {
        "kernel.dmesg_restrict" = 1;
        "kernel.kptr_restrict" = 2;
        "kernel.yama.ptrace_scope" = 1;
        "fs.protected_hardlinks" = 1;
        "fs.protected_symlinks" = 1;
      };
    };
    */
  };
}
