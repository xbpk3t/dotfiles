{
  hostMeta,
  lib,
  ...
}:
let
  isAgent = hostMeta.role == "agent";
  isServer = !isAgent;

  # Server 角色：curated cockpit，不整包 import home/base。
  serverImports = [
    ../../home/base/devops/rclone.nix
    ../../home/base/devops/ghui.nix
    ../../home/base/devops/hunk.nix
    ../../home/base/devops/yazi.nix # herdr ctrl+alt+y
    # helix.nix 在 let 层读取 modules.langs.lsp.packages，需要 lsp 的 option 定义。
    ../../home/base/langs/lsp.nix
    ../../home/base/devops/helix.nix # ghui/yazi/$EDITOR → hx
    ../../home/base/AI/claude.nix
    ../../home/base/AI/skills.nix
    ../../home/base/AI/dagu.nix
  ];

  # Agent 角色：完整 home/base + home/nixos。
  agentImports = [
    ../../home/base
    ../../home/nixos
  ];
in
{
  imports = if isAgent then agentImports else serverImports;

  config = lib.mkMerge [
    {
      modules = {
        infra = {
          nh.enable = true;
          networking.enable = true;
        };

        devops.ssh = {
          enable = isAgent;
          github.enable = true;
        };

        AI = {
          claude.enable = true;
          skills.enable = true;
          dagu = {
            enable = true;
            # 避开 VPS 上 axonhub 的 8090 和给 qbittorrent 预留的 8080。
            port = 8081;
            schedulerPort = 8091;
          };
        };
      };
    }

    (lib.mkIf isServer {
      modules.devops = {
        ghui.enable = true;
        hunk.enable = true;
      };

      # VPS 上 Caddy 管理 edge 网络，所有服务都需要以 external 方式加入。
      home.sessionVariables.EDGE_NETWORK_EXTERNAL = "true";
    })

    # 这两个 option 只在 agent 侧 import，server 上不能引用（mkIf false 也要求 option 已声明）。
    (lib.optionalAttrs isAgent {
      modules = {
        ms.k8s.enable = true;
        AI.opencli-browser.enable = true;
      };
    })
  ];
}
