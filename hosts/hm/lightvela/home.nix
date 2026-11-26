{
  config,
  mylib,
  pkgs,
  ...
}:
{
  imports = [
    (mylib.relativeToRoot "home/hm")
    (mylib.relativeToRoot "secrets/hm-lightvela.nix")
  ]
  ++ map mylib.relativeToRoot [
    # dev 环境：与 macos-ws / vps-dev 同一套 home/base 开关，节点显式 import。
    "home/base/devops/direnv.nix"
    "home/base/devops/helix.nix"
    "home/base/infra/nix-tools.nix"
    "home/base/langs"

    # host 的 modules.AI.* 开关需要这些 option 定义；不 import dagu
    # （它的顶层 config 引用在 standalone HM 里会触发 infinite recursion）。
    "home/base/AI/apm.nix"
    "home/base/AI/claude.nix"
    "home/base/AI/codex.nix"
    "home/base/AI/dsh.nix"
    "home/base/AI/mcp.nix"
    "home/base/AI/ocr.nix"
    "home/base/AI/opencode.nix"
    "home/base/AI/skills.nix"
  ];

  # 厂商 PA 当前授权的是 root（hermes-workbench-client）；不建 luck。
  # homeDirectory/stateVersion 由 home/core/init.nix 从 username / meta 派生。
  # 如果改用 desk 登录，把 username 改成 "desk"。
  home = {
    username = "root";

    # nezha-agent 供 systemd system service 使用；其余 dev 工具走 modules。
    packages = with pkgs; [
      nezha-agent
    ];
  };

  # `ff` 系统信息入口；其他 host 走 modules.devops.fetch，hm 轨也补上。
  modules = {
    devops = {
      fetch = {
        enable = true;
        driver = "microfetch";
      };

      helix.enable = true;
      direnv.enable = false;
    };

    infra.nix-tools.enable = true;

    langs = {
      basePackages.enable = true;

      lsp.enable = true;

      treefmt.enable = true;
      golang.enable = true;
      python.enable = true;
      ts.enable = true;
    };

    AI = {
      apm.enable = true;
      ocr.enable = true;
      claude = {
        enable = true;
        permissionMode = "yolo";
      };
      skills.enable = true;
      mcp.isDesktop = false;
    };
  };

  # Nezha agent config (N1). The agent v1 reads JSON, not YAML. The secret is
  # rendered by sops-nix; the system service waits for this file before starting.
  #
  # server 从 fleet registry 派生（hub 节点的 tailscale.ip:port），与 NixOS 侧
  # modules/infra/nezha.nix 共用同一事实源；hub 换 IP/端口时这里不用手改。
  sops.templates."nezha-config".content = builtins.toJSON {
    server = mylib.fleet.nezha.server;
    client_secret = config.sops.placeholder.NEZHA_AGENT_SK;
    uuid = "42ff60cb-0845-4a85-bb67-509475d7e05f";
    tls = false;
    disable_command_execute = true;
    disable_auto_update = true;
    disable_force_update = true;
  };

  home.file.".config/nezha/config.json".source =
    config.lib.file.mkOutOfStoreSymlink
      config.sops.templates."nezha-config".path;
}
