{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.modules.ssh;
in {
  options.modules.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";

    hosts = {
      github = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable GitHub SSH configuration";
        };
      };

      vps = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable VPS SSH configuration";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      sshs
      termscp
      sshpass
    ];

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
        // lib.optionalAttrs cfg.hosts.vps.enable {
          "vps" = {
            hostname = "47.79.17.202";
            user = "root";
            port = 22;
            identityFile = config.sops.secrets.sshVpsPrivateKey.path;
          };
        };
    };
  };
}
