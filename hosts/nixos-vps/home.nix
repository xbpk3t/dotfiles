{
  hostMeta,
  lib,
  mylib,
  ...
}:
let
  isAgent = (hostMeta.role or "server") == "agent";
  isServer = !isAgent;

  # Server 角色：沿用原来的 curated cockpit，不整包 import home/base。
  serverImports = [
    "home/base/devops/rclone.nix"
    "home/base/devops/herdr.nix"
    "home/base/devops/ghui.nix"
    "home/base/devops/hunk.nix"
    "home/base/devops/yazi.nix" # herdr ctrl+alt+y
    # helix.nix reads modules.langs.lsp.packages — import option def; leave lsp.enable false
    "home/base/langs/lsp.nix"
    "home/base/devops/helix.nix" # ghui/yazi/$EDITOR → hx; herdr popup open paths
    # k9s (+ kubectl toolchain). VPS already runs k3s; herdr ctrl+alt+k.
    "home/base/ms/k8s.nix"
    # Claude + shared skills (herdr ctrl+alt+a / resume_agents_on_restore hook)
    "home/base/AI/claude.nix"
    "home/base/AI/skills.nix"
    # DAG scheduler；wiki-digest 的目标主机就是 VPS（DAG 内用 hostname precondition gate）
    "home/base/AI/dagu.nix"
    # agent 专属 capability 的 option definition；server 上 enable=false，不启服务。
    "home/base/AI/opencli-browser.nix"
  ];

  # Agent 角色：完整 home/base + home/nixos（无 GNOME 系统层）。
  agentImports = [
    "home/base"
    "home/nixos"
  ];

in
{
  imports = map mylib.relativeToRoot (if isAgent then agentImports else serverImports);

  # Server 上 Caddy 管理 edge 网络，所有服务都需要以 external 方式加入。
  home.sessionVariables.EDGE_NETWORK_EXTERNAL = lib.mkIf isServer "true";

  modules = {
    infra = {
      nh.enable = true;
      networking.enable = true;
    };

    # Server 当前不使用 k8s 工具链；agent 需要 k9s/kubectl。
    ms.k8s.enable = isAgent;

    devops = {
      herdr.enable = false;
      ghui.enable = isServer;
      hunk.enable = isServer;

      ssh = {
        enable = isAgent;
        hosts = {
          github.enable = true;
          hk-hdy.enable = true;
        };
      };
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
      opencli-browser.enable = isAgent;
    };
  };
}
