{pkgs, ...}: {
  # Aerospace 服务配置（平铺窗口管理）
  # https://mynixos.com/nixpkgs/package/aerospace
  # https://mynixos.com/nix-darwin/options/services.aerospace
  services.aerospace = {
    enable = true;
    package = pkgs.aerospace;

    # 细项配置，对应 services.aerospace.settings*
    settings = {
      # 登录后执行的命令列表（空数组=不执行）
      after-login-command = [];

      # 程序启动完成后执行的命令列表（空数组=不执行）
      after-startup-command = [];

      # 自动扁平化嵌套容器，减少层级
      enable-normalization-flatten-containers = true;

      # 嵌套容器时反转方向，维持更自然的分割方向
      enable-normalization-opposite-orientation-for-nested-containers = true;

      # 根容器默认布局/方向
      default-root-container-layout = "tiles";
      default-root-container-orientation = "horizontal";

      # 切换聚焦显示器时，将鼠标移动到该屏幕中心
      on-focused-monitor-changed = ["move-mouse monitor-lazy-center"];

      # 聚焦时自动显示被隐藏的 macOS 应用
      automatically-unhide-macos-hidden-apps = true;

      # 鼠标拖拽调整窗口大小的修饰键
      mouse-resize-modifier = "cmd";

      # 键盘映射
      key-mapping = {
        preset = "qwerty";
      };

      # 窗口间隙
      gaps = {
        inner = {
          horizontal = 12;
          vertical = 12;
        };
        outer = {
          left = 12;
          bottom = 12;
          top = 12;
          right = 12;
        };
      };

      # 模式与快捷键绑定
      mode = {
        main = {
          binding = {
            # 打开 Ghostty 终端
            cmd-enter = ''exec-and-forget open -a "Ghostty"'';

            # 焦点移动
            cmd-ctrl-h = "focus left";
            cmd-ctrl-j = "focus down";
            cmd-ctrl-k = "focus up";
            cmd-ctrl-l = "focus right";

            # 窗口移动
            cmd-shift-h = "move left";
            cmd-shift-j = "move down";
            cmd-shift-k = "move up";
            cmd-shift-l = "move right";

            # 工作区切换
            cmd-1 = "workspace 1";
            cmd-2 = "workspace 2";
            cmd-3 = "workspace 3";
            cmd-4 = "workspace 4";
            cmd-5 = "workspace 5";
            cmd-6 = "workspace 6";
            cmd-7 = "workspace 7";
            cmd-8 = "workspace 8";
            cmd-9 = "workspace 9";

            # 将窗口移动到对应工作区
            cmd-shift-1 = "move-node-to-workspace 1";
            cmd-shift-2 = "move-node-to-workspace 2";
            cmd-shift-3 = "move-node-to-workspace 3";
            cmd-shift-4 = "move-node-to-workspace 4";
            cmd-shift-5 = "move-node-to-workspace 5";
            cmd-shift-6 = "move-node-to-workspace 6";
            cmd-shift-7 = "move-node-to-workspace 7";
            cmd-shift-8 = "move-node-to-workspace 8";
            cmd-shift-9 = "move-node-to-workspace 9";

            # 在最近使用的两个工作区间切换
            alt-tab = "workspace-back-and-forth";

            # 进入 service 模式
            cmd-ctrl-semicolon = "mode service";
          };
        };

        service = {
          binding = {
            # 退出 service 模式并重载配置
            esc = ["reload-config" "mode main"];

            # 重置布局并返回 main 模式
            r = ["flatten-workspace-tree" "mode main"];
          };
        };
      };
    };
  };

  # jankyborders 高亮当前窗口，配合 Aerospace 使用
  # https://mynixos.com/nixpkgs/package/jankyborders
  # https://mynixos.com/nix-darwin/options/services.jankyborders
  services.jankyborders = {
    enable = true;
    settings = {
      style = "round";
      width = 6.0;
      hidpi = "on";
      active_color = "0xfff7768e";
      inactive_color = "0xffe1e3e4";
    };
  };
}
