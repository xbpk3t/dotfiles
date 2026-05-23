{
  config,
  lib,
  ...
}: let
  cfg = config.modules.devops.ssh;
in {
  options.modules.devops.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";

    hosts = {
      github = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      hk-hdy = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      LA = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      homelab = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks =
        {
          "*" = {
            addKeysToAgent = "yes";
            controlMaster = "no";
            controlPersist = "no";
            hashKnownHosts = true;
            serverAliveInterval = 15;
            serverAliveCountMax = 6;
            compression = true;
            forwardAgent = true;
            forwardX11 = false;
          };
        }
        // lib.optionalAttrs cfg.hosts.github.enable {
          "github.com" = {
            hostname = "ssh.github.com";
            user = "git";
            port = 443;
            identityFile = config.sops.secrets.SSH_GITHUB.path;
            identitiesOnly = true;
          };
        }
        // lib.optionalAttrs cfg.hosts.hk-hdy.enable {
          # HDY机器
          # match both alias 和 裸IP 在一条 Host 规则
          # 只有 Host hk，当你写 ssh luck@103.85.224.63，OpenSSH 先用精确 Host/IP 匹配，没有找到，再走 Host *，没用上 HK 的 key，所以被拒。
          "103.85.224.63" = {
            hostname = "103.85.224.63";
            user = "luck";
            port = 22;
            identityFile = config.sops.secrets.SSH_HDY.path;
            identitiesOnly = true;
          };
        }
        // lib.optionalAttrs cfg.hosts.LA.enable {
          # RN机器
          "192.129.183.26" = {
            hostname = "192.129.183.26";
            user = "luck";
            port = 22;
            identityFile = config.sops.secrets.SSH_RACKNERD.path;
            identitiesOnly = true;
          };
        }
        // lib.optionalAttrs cfg.hosts.homelab.enable {
          "100.81.204.63" = {
            hostname = "100.81.204.63";
            user = "luck";
            port = 22;
          };
        };
    };

    # 覆盖 ~/.ssh/config
    home.file.".ssh/config".force = true;
  };
}
