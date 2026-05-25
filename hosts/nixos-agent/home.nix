{
  config,
  pkgs,
  ...
}: {
  # Agent 容器只包含 AI 工具链，不含任何桌面/IDE/图形组件
  modules = {
    AI = {
      claude = {
        enable = true;
        permissionMode = "yolo";
      };
      mcp.enable = true;
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

  # MCP 需要 gh CLI 用于 github auth
  programs.gh.enable = true;
}
