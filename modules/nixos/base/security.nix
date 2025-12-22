{
  config,
  lib,
  pkgs,
  myvars,
  ...
}: let
  inherit (lib) mkMerge mkIf mkDefault mkEnableOption;
  isDesktop = config.modules.roles.isDesktop;
  isServer = config.modules.roles.isServer;
  # 高 ulimit 开关（放宽资源限制）
  enableHighLimits = config.modules.security.enableHighLimits or false;
  authorizedKeys =
    (myvars.mainSshAuthorizedKeys or [])
    ++ (myvars.secondaryAuthorizedKeys or []);
in {
  options.modules.security.enableHighLimits = mkEnableOption ''
    启用高 ulimit 档（基于 Linux-Optimizer）：放宽 nofile/stack 等资源限制，适合高并发/压测/调试。
    默认关闭以保持安全基线（core=0）。
  '';
  # https://mynixos.com/nixpkgs/options/security

  config = mkMerge [
    {
      # 内核与进程隔离相关的安全 sysctl（作用域需在顶层）
      boot.kernel.sysctl = {
        # 仅 root 可读 dmesg
        "kernel.dmesg_restrict" = 1;
        # 隐藏内核指针
        "kernel.kptr_restrict" = 2;
        # 禁止跨用户 ptrace
        "kernel.yama.ptrace_scope" = 1;
        # 防止硬链接提权
        "fs.protected_hardlinks" = 1;
        # 防止符号链接攻击
        "fs.protected_symlinks" = 1;
        # 如果关闭 systemd-coredump，则使用普通 core 文件名
        # "kernel.core_pattern" = "core";
      };

      security = {
        # 基础安全基线（不含 AppArmor/SELinux）

        # 审计日志，记录关键安全事件
        auditd.enable = lib.mkDefault false;

        # /etc/login.defs 基线密码策略
        loginDefs = {
          # 仅 root/本用户/主组可改 GECOS
          chfnRestrict = "rwh";
          settings = {
            # 密码最大有效期（天）
            PASS_MAX_DAYS = 90;
            # 密码最小更改间隔（天）
            PASS_MIN_DAYS = 7;
            # 到期前提醒（天）
            PASS_WARN_AGE = 14;
            # 加密算法
            ENCRYPT_METHOD = "SHA512";
          };
        };

        # sudo 留痕（追加到已存在的 extraConfig）
        sudo.extraConfig = lib.mkAfter ''
          Defaults logfile="/var/log/sudo.log"
        '';
      };

      # 默认关闭 systemd-coredump，避免生成大体积 core 文件
      systemd.coredump.enable = false;

      networking.firewall = mkMerge [
        {
          # 基线：保留由其他模块设置的值，这里不强制开启
        }
        (mkIf isServer {
          # 服务器强制开启防火墙，只放行 22，并记录拒绝
          enable = lib.mkForce true;
          allowedTCPPorts = lib.mkDefault [22];
          logRefusedConnections = lib.mkDefault true;
        })
      ];
    }

    (mkIf isServer {
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

        sudo.wheelNeedsPassword = lib.mkDefault true;
      };

      users = {
        # 让 /etc/passwd 等完全由 Nix 声明管理，禁止用 passwd/useradd 等在机器上临时改用户或密码。VPS 通常当作不可变基础设施，防止手动漂移和被入侵者添加账户；桌面常见场景是需要临时改密码或加本地用户，因此不默认强制。
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
    })

    (mkIf isDesktop {
      # https://mynixos.com/nixpkgs/options/security.apparmor
      # PLAN AppArmor

      # https://mynixos.com/nixpkgs/package/bubblewrap

      # 桌面特定：密钥/代理便捷功能
      # seahorse is a GUI App for GNOME Keyring.
      programs.seahorse.enable = true;

      # The OpenSSH agent remembers private keys for you
      # so that you don’t have to type in passphrases every time you make an SSH connection.
      # Use `ssh-add` to add a key to the agent.
      programs.ssh.startAgent = true;

      # gpg agent with pinentry
      programs.gnupg.agent = {
        enable = true;
        pinentryPackage = pkgs.pinentry-qt;
        # default-cache-ttl in seconds (4 hours)
        settings.default-cache-ttl = 4 * 60 * 60;
        enableSSHSupport = false;
      };
    })
  ];
}
