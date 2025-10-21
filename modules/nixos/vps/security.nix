# NixOS security services configuration
# This module demonstrates how to configure fail2ban and clamav on NixOS
# Note: These services are only available on NixOS, not on nix-darwin (macOS)
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  config = mkIf config.services.sec.enable {
    services = {
      # Enable fail2ban for intrusion prevention

      # 监控日志，自动封禁恶意 IP（防止 SSH 暴力破解等）
      fail2ban = {
        enable = true;

        # Maximum number of retries before banning
        maxretry = 3;

        # Ban time in seconds (1 hour)
        bantime = "1h";

        # Time window for counting failures (1 hour)
        findtime = "1h";

        # Ignore localhost and private networks
        ignoreIP = [
          "127.0.0.1/8"
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
        ];

        # Configure jails for different services
        jails = {
          # SSH protection
          sshd = {
            enabled = true;
            port = "ssh";
            filter = "sshd";
            logpath = "/var/log/auth.log";
            maxretry = 3;
            bantime = "1h";
            findtime = "1h";
          };

          # Nginx protection (if nginx is enabled)
          nginx-http-auth = lib.mkIf config.services.nginx.enable {
            enabled = true;
            port = "http,https";
            filter = "nginx-http-auth";
            logpath = "/var/log/nginx/error.log";
            maxretry = 5;
            bantime = "1h";
            findtime = "1h";
          };

          # Nginx limit request protection
          nginx-limit-req = lib.mkIf config.services.nginx.enable {
            enabled = true;
            port = "http,https";
            filter = "nginx-limit-req";
            logpath = "/var/log/nginx/error.log";
            maxretry = 10;
            bantime = "1h";
            findtime = "1h";
          };
        };

        # Custom daemon configuration
        daemonConfig = ''
          [Definition]
          logtarget = /var/log/fail2ban.log
          loglevel = INFO
          socket = /run/fail2ban/fail2ban.sock
          pidfile = /run/fail2ban/fail2ban.pid
        '';
      };
      # Enable ClamAV antivirus
      # 文件系统病毒扫描，适合文件服务器或邮件服务器
      clamav = {
        daemon = {
          enable = true;

          # ClamAV daemon configuration
          settings = {
            # Log settings
            LogFile = "/var/log/clamav/clamd.log";
            LogTime = true;
            LogClean = false;
            LogSyslog = false;
            LogFacility = "LOG_LOCAL6";
            LogVerbose = false;
            LogRotate = true;

            # Database settings
            DatabaseDirectory = "/var/lib/clamav";

            # Scanning settings
            MaxScanSize = "100M";
            MaxFileSize = "25M";
            MaxRecursion = 16;
            MaxFiles = 10000;
            MaxEmbeddedPE = "10M";
            MaxHTMLNormalize = "10M";
            MaxHTMLNoTags = "2M";
            MaxScriptNormalize = "5M";
            MaxZipTypeRcg = "1M";

            # Performance settings
            MaxThreads = 12;
            ReadTimeout = 180;
            CommandReadTimeout = 5;
            SendBufTimeout = 200;
            MaxQueue = 100;
            IdleTimeout = 30;

            # Security settings
            SelfCheck = 3600;
            User = "clamav";
            AllowSupplementaryGroups = true;

            # Network settings
            TCPSocket = 3310;
            TCPAddr = "127.0.0.1";

            # Exclude certain file types from scanning
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

        # Enable automatic virus definition updates
        updater = {
          enable = true;

          # Update frequency (4 times per day)
          frequency = 6;

          # Updater configuration
          settings = {
            # Log settings
            UpdateLogFile = "/var/log/clamav/freshclam.log";
            LogVerbose = false;
            LogSyslog = false;
            LogFacility = "LOG_LOCAL6";
            LogFileMaxSize = "2M";
            LogRotate = true;
            LogTime = true;

            # Database settings
            DatabaseDirectory = "/var/lib/clamav";
            DatabaseOwner = "clamav";

            # Update settings
            DNSDatabaseInfo = "current.cvd.clamav.net";
            DatabaseMirror = [
              "db.local.clamav.net"
              "database.clamav.net"
            ];

            # Connection settings
            MaxAttempts = 5;
            ConnectTimeout = 30;
            ReceiveTimeout = 30;

            # Notification settings
            NotifyClamd = "/etc/clamav/clamd.conf";

            # Safety settings
            Checks = 24;

            # Proxy settings (if needed)
            # HTTPProxyServer = "proxy.example.com";
            # HTTPProxyPort = 8080;
          };
        };
      };

      # Configure log rotation for security logs
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
    };

    # Additional security packages
    environment.systemPackages = with pkgs; [
      fail2ban
      clamav

      # Security auditing tool
      lynis
      # Rootkit hunter
      rkhunter
      # Another rootkit checker
      chkrootkit
      # Advanced Intrusion Detection Environment
      aide
      # Log analysis tool
      logwatch
      # Port Scan Attack Detector
      psad
    ];

    # Enable firewall with basic rules
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [22 80 443];
      allowedUDPPorts = [];
      allowPing = true;
      logRefusedConnections = true;
      logRefusedPackets = false;
      logRefusedUnicastsOnly = false;
    };

    # System security hardening
    security = {
      # Enable audit daemon for security monitoring
      # 记录系统调用、文件访问、权限变更等安全事件
      auditd.enable = true;
      audit = {
        enable = true;
        rules = [
          # Monitor file access
          "-w /etc/passwd -p wa -k identity"
          "-w /etc/group -p wa -k identity"
          "-w /etc/shadow -p wa -k identity"
          "-w /etc/sudoers -p wa -k identity"

          # Monitor system calls
          "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change"
          "-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change"

          # Monitor network configuration changes
          "-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale"
          "-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale"
        ];
      };
      # Disable sudo password for wheel group (optional, comment out for more security)
      # sudo.wheelNeedsPassword = false;

      # Enable AppArmor (if available)
      apparmor.enable = lib.mkDefault true;

      # Kernel hardening
      forcePageTableIsolation = true;

      # Disable core dumps
      pam.loginLimits = [
        {
          domain = "*";
          type = "hard";
          item = "core";
          value = "0";
        }
      ];
    };

    # Additional system hardening via kernel parameters
    boot.kernel.sysctl = {
      # Network security
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv4.conf.default.send_redirects" = 0;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.default.accept_redirects" = 0;
      "net.ipv4.conf.all.secure_redirects" = 0;
      "net.ipv4.conf.default.secure_redirects" = 0;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
      "net.ipv4.tcp_syncookies" = 1;

      # Kernel security
      "kernel.dmesg_restrict" = 1;
      "kernel.kptr_restrict" = 2;
      "kernel.yama.ptrace_scope" = 1;

      # File system security
      "fs.protected_hardlinks" = 1;
      "fs.protected_symlinks" = 1;
    };
  };
}
