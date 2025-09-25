_: {
  programs.fastfetch = {
    enable = true;

    # 自定义配置
    settings = {
      # 显示的信息模块
      modules = [
        "title"
        "separator"
        "os"
        "host"
        "kernel"
        "uptime"
        "packages"
        "shell"
        "display"
        "de"
        "wm"
        "wmtheme"
        "theme"
        "icons"
        "font"
        "cursor"
        "terminal"
        "terminalfont"
        "cpu"
        "gpu"
        "memory"
        "swap"
        "disk"
        "localip"
        "battery"
        "poweradapter"
        "locale"
        "break"
        "colors"
      ];

      # 显示设置
      display = {
        # 分隔符
        separator = "  ";
        # 颜色主题
        color = {
          keys = "blue";
          title = "green";
        };
      };

      # Logo 设置
      logo = {
        # 使用系统默认 logo
        source = "auto";
        # logo 大小
        width = 65;
        height = 20;
        # logo 位置
        padding = {
          top = 1;
          left = 2;
        };
      };
    };
  };
}
