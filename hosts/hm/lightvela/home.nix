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
  ];

  # 厂商 PA 当前授权的是 root（hermes-workbench-client）；不建 luck。
  # homeDirectory/stateVersion 由 home/core/init.nix 从 username / meta 派生。
  # 如果改用 desk 登录，把 username 改成 "desk"。
  home = {
    username = "root";

    # git/gh 的 editorMeta.command 是 hx；补上 helix。
    # nezha-agent 供 systemd system service 使用。
    packages = with pkgs; [
      helix
      nezha-agent
    ];
  };

  # `ff` 系统信息入口；其他 host 走 modules.devops.fetch，hm 轨也补上。
  modules.devops.fetch = {
    enable = true;
    driver = "microfetch";
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
