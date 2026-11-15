{
  config,
  lib,
  mylib,
  hostMeta,
  ...
}:
let
  cfg = config.modules.devops.ssh;

  # 本机不在 tailnet 时没有可用寻址，不生成节点条目（只保留 github）。
  selfOnTailnet = hostMeta ? tailscale && hostMeta.tailscale ? ip;

  # fleet SSH 统一策略：Host 键 = inventory 节点名，地址 = 节点 tailnet IP，用户 = inventory 用户。
  # 加机器只改 lib/inventory/data.nix（补 tailscale.ip），这里零改动。
  tailnetNodes = lib.filterAttrs (
    _: node: node ? tailscale && node.tailscale ? ip
  ) mylib.inventory.nodes;

  mkHost = node: {
    hostname = node.tailscale.ip;
    user = node.user.username;
  };
in
{
  options.modules.devops.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";

    github = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
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
      // lib.optionalAttrs cfg.github.enable {
        "github.com" = {
          hostname = "ssh.github.com";
          user = "git";
          port = 443;
          identityFile = config.sops.secrets.SSH_GITHUB.path;
          identitiesOnly = true;
        };
      }
      // lib.optionalAttrs selfOnTailnet (
        lib.mapAttrs' (name: node: lib.nameValuePair name (mkHost node)) tailnetNodes
      );
    };

    # 覆盖 ~/.ssh/config
    home.file.".ssh/config".force = true;
  };
}
