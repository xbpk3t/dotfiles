{
  config,
  lib,
  pkgs,
  ...
}: {
  # Agent 容器只包含 AI 工具链，不含任何桌面/IDE/图形组件

  # headless 环境下 gh auth login 不可用，通过 sops secret 注入 token
  # mkForce：覆盖 zsh.nix 中 GITHUB_TOKEN="$(gh auth token)" 的动态获取（容器无 gh auth 登录态）
  home.sessionVariables = {
    GITHUB_TOKEN = lib.mkForce "$(cat ${config.sops.secrets.GITHUB_TOKEN.path})";
  };

  modules = {
    AI = {
      claude = {
        enable = true;
        permissionMode = "yolo";
      };
      skills.enable = true;
    };
    infra = {
      nh.enable = true;
      networking.enable = true;
    };
  };

  home.packages = with pkgs; [
    # 容器调试工具
    htop
    iotop
    lsof
    tcpdump
  ];
}
