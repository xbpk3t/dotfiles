{
  config,
  globals,
  lib,
  mylib,
  hostMeta,
  ...
}:
let
  cfg = config.modules.devops.ssh;

  # 本机不在 tailnet 时没有可用寻址，不生成节点条目（只保留 github）。
  selfOnTailnet = hostMeta ? tailscale && hostMeta.tailscale ? ip;

  # fleet SSH 统一策略：Host 键 = 节点名，地址 = 节点 tailnet IP。
  # 用户名是全局身份常量，不在每个节点重复。
  # 加机器只在 hosts/<group>/<node>/meta.nix 补 tailscale.ip，这里零改动。
  tailnetNodes = mylib.fleet.tailnetNodes;

  # 交互式高延迟 host 的连接复用；不要加到 Host *：
  # - deploy-rs / nix ssh-ng 等自动化连接不应共享用户 master
  # - github.com 是短连接，stale master 反而会制造故障
  # 节点通过 meta.nix 的 `ssh.multiplex = true` opt-in。
  mux = {
    controlMaster = "auto";
    controlPath = "~/.ssh/control-%C";
    controlPersist = "10m";
  };

  mkHost =
    node:
    {
      hostname = node.tailscale.ip;
      user = globals.identity.user.username;
    }
    // lib.optionalAttrs (lib.attrByPath [ "ssh" "multiplex" ] false node) mux;
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
