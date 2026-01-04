{
  config,
  lib,
  ...
}: let
  cfg = config.modules.ssh;
in {
  # 给ssh的各host做了配置化启用，方便给不同 nix host自定义配置（比如说workstation可能会启用全部host，而VPS则不启用任何host）
  options.modules.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";

    hosts = {
      github = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };

      hk-claw = {
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
            identityFile = config.sops.secrets.sshGithubPrivateKey.path;
            identitiesOnly = true;
          };
        }
        // lib.optionalAttrs cfg.hosts.hk.enable {
          # HDY机器
          # match both alias 和 裸IP 在一条 Host 规则
          # 只有 Host hk，当你写 ssh luck@103.85.224.63，OpenSSH 先用精确 Host/IP 匹配，没有找到，再走 Host *，没用上 HK 的 key，所以被拒。
          "HK-hdy 103.85.224.63" = {
            hostname = "103.85.224.63";
            user = "luck";
            port = 22;
            identityFile = config.sops.secrets.sshHKPrivateKey.path;
            identitiesOnly = true;
          };
        }
        // lib.optionalAttrs cfg.hosts.LA.enable {
          # RN机器
          "LA-RN 142.171.154.61" = {
            hostname = "142.171.154.61";
            user = "luck";
            port = 22;
            identityFile = config.sops.secrets.sshLAPrivateKey.path;
            identitiesOnly = true;
          };
        }
        // lib.optionalAttrs cfg.hosts.vps.enable {
          "HK-claw 47.79.17.202" = {
            hostname = "47.79.17.202";
            user = "root";
            port = 22;
            identityFile = config.sops.secrets.sshHKClawPrivateKey.path;
          };
        };
    };
  };
}
