{
  config,
  lib,
  pkgs,
  myvars,
  ...
}: let
  inherit (lib) mkDefault;
  # 高 ulimit 开关（放宽资源限制）
  enableHighLimits = config.modules.security.enableHighLimits;
  authorizedKeys = myvars.SSHPubKeys or [];
  enableFirewall = config.modules.security.enableFirewall;
in {
  config = {
    security = {
      # 服务器角色：pam/审计等的默认偏向保守；可选启用高 ulimit 档
      pam.loginLimits =
        if enableHighLimits
        then [
          # 高 ulimit 档（基于 Linux-Optimizer），偏向高并发/调试，可能放大泄露或 DoS 面
          # 把几乎所有资源（core/data/fsize/sigpending/memlock/rss/msgqueue/cpu/nproc/as/locks等）设为 unlimited，并把 nofile 提到 1048576，stack 软/硬 32M/64M。
          # The maximum size of core files created
          {
            domain = "*";
            type = "-";
            item = "core";
            value = "unlimited";
          }
          # The maximum size of a process's data segment
          {
            domain = "*";
            type = "-";
            item = "data";
            value = "unlimited";
          }
          # The maximum size of files created by the shell (default option)
          {
            domain = "*";
            type = "-";
            item = "fsize";
            value = "unlimited";
          }
          # The maximum number of pending signals
          {
            domain = "*";
            type = "-";
            item = "sigpending";
            value = "unlimited";
          }
          # The maximum size that may be locked into memory
          {
            domain = "*";
            type = "-";
            item = "memlock";
            value = "unlimited";
          }
          # The maximum memory size
          {
            domain = "*";
            type = "-";
            item = "rss";
            value = "unlimited";
          }
          # The maximum number of open file descriptors
          {
            domain = "*";
            type = "-";
            item = "nofile";
            value = "1048576";
          }
          # The maximum POSIX message queue size
          {
            domain = "*";
            type = "-";
            item = "msgqueue";
            value = "unlimited";
          }
          # The maximum stack size (soft limit)
          {
            domain = "*";
            type = "-";
            item = "stack";
            value = "32768";
          }
          # The maximum stack size (hard limit)
          {
            domain = "*";
            type = "hard";
            item = "stack";
            value = "65536";
          }
          # The maximum number of seconds to be used by each process
          {
            domain = "*";
            type = "-";
            item = "cpu";
            value = "unlimited";
          }
          # The maximum number of processes available to a single user
          {
            domain = "*";
            type = "-";
            item = "nproc";
            value = "unlimited";
          }
          # The maximum amount of virtual memory available to the process
          {
            domain = "*";
            type = "-";
            item = "as";
            value = "unlimited";
          }
          # The maximum number of file locks
          {
            domain = "*";
            type = "-";
            item = "locks";
            value = "unlimited";
          }
        ]
        else [
          # 安全基线：禁止 core 文件，减少敏感信息泄露
          {
            domain = "*";
            type = "hard";
            item = "core";
            value = "0";
          }
        ];

      sudo.wheelNeedsPassword = mkDefault true;
    };

    users = {
      # 让 /etc/passwd 等完全由 Nix 声明管理，禁止用 passwd/useradd 等在机器上临时改用户或密码。
      mutableUsers = mkDefault false;
      # 为 root 预置救援公钥：禁用密码登录后仍可用该密钥 SSH 登入修复系统
      users.root.openssh.authorizedKeys.keys = authorizedKeys;
    };

    services = {
      fail2ban = {
        # 启用 fail2ban 反暴力破解
        enable = true;
        # 选用默认包
        package = pkgs.fail2ban;
        # 最大重试次数
        maxretry = 3;
        # 封禁时长
        bantime = "1h";
        # 白名单网段
        ignoreIP = [
          "127.0.0.1/8"
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
        ];
        jails = {
          DEFAULT.settings = {
            # 窗口期
            findtime = "15m";
          };

          sshd = {
            # 开启 sshd jail
            enabled = true;
            settings = {
              # 监控端口
              port = "ssh";
              # 最大重试次数
              maxretry = 3;
              # 封禁时长
              bantime = "1h";
              # 后端
              backend = "systemd";
            };
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

    networking.firewall = lib.mkMerge [
      (lib.mkIf enableFirewall {
        # 服务器/显式开启：强制开防火墙，至少放行 22，并记录拒绝
        enable = lib.mkForce true;
        allowedTCPPorts = lib.mkDefault [22];
        logRefusedConnections = lib.mkDefault true;
      })
      (lib.mkIf (!enableFirewall) {
        # 显式关闭：覆盖上游强制开启
        enable = lib.mkForce false;
      })
    ];
  };
}
