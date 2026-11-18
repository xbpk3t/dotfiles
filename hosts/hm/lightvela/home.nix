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
  # 如果改用 desk 登录，改成：
  #   username = "desk"; homeDirectory = "/home/desk";
  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "26.05";

    # git/gh 的 editorMeta.command 是 hx；补上 helix。
    # nezha-agent 供 systemd system service 使用。
    packages = with pkgs; [
      helix
      nezha-agent
    ];
  };

  programs.home-manager.enable = true;

  # Nezha agent config (N1). The agent v1 reads JSON, not YAML. The secret is
  # rendered by sops-nix; the system service waits for this file before starting.
  sops.templates."nezha-config".content = builtins.toJSON {
    server = "100.101.189.7:8008";
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
