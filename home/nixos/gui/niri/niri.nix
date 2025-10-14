{
  config,
  pkgs,
  ...
}: let
  # 基于 hyprland 配置的变量定义
  mod = "Mod"; # niri 使用 "Mod" 代表 Super 键
  browser = "chromium-browser";
  terminal = "alacritty";
  IDE = "goland";
in {
  # 安装 xwayland-satellite 以支持 X11 应用（如 GoLand）
  home.packages = with pkgs; [
    xwayland-satellite
  ];

  # Niri compositor 配置
  # 基于 hyprland 配置进行迁移
  programs.niri = {
    enable = true;

    settings = {
      # 输入设备配置（基于 hyprland 的 input 配置）
      input = {
        keyboard = {
          xkb = {
            layout = "us";
          };
        };

        # 触摸板配置（基于 hyprland 的 touchpad 配置）
        touchpad = {
          # 自然滚动（对应 hyprland 的 natural_scroll = 1）
          natural-scroll = true;

          # 轻触点击（对应 hyprland 的 tap-to-click = true）
          tap = true;

          # 拖拽锁定（对应 hyprland 的 drag_lock = 2）
          dwt = true; # disable-while-typing

          # 滚动速度（对应 hyprland 的 scroll_factor = 0.2）
          scroll-factor = 0.2;

          # 点击方式（对应 hyprland 的 clickfinger_behavior = true）
          click-method = "clickfinger";

          # 加速配置
          accel-speed = 0.0;
          accel-profile = "flat";
        };

        # 鼠标配置
        mouse = {
          accel-speed = 0.0;
          accel-profile = "flat";
        };

        # 焦点跟随鼠标（对应 hyprland 的 follow_mouse = 1）
        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "0%";
        };
      };

      # 输出配置（基于 hyprland 的 monitor 配置）
      outputs = {
        # 默认输出配置（对应 hyprland 的 monitor = ", preferred, auto, 1"）
        # niri 会自动检测显示器
      };

      # 布局配置（基于 hyprland 的 general 和 dwindle 配置）
      layout = {
        # 焦点环配置（对应 hyprland 的 border 配置）
        focus-ring = {
          # 禁用焦点环（对应 hyprland 的 border_size = 0）
          enable = false;
          width = 0;
        };

        # 边框配置
        border = {
          enable = false;
          width = 0;
        };

        # 间距配置（对应 hyprland 的 gaps_in/out = 5）
        gaps = 5;

        # 居中布局
        center-focused-column = "never";

        # 预设列宽
        preset-column-widths = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
        ];

        # 默认列宽
        default-column-width = {proportion = 0.5;};

        # 预设窗口高度
        preset-window-heights = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
        ];
      };

      # 窗口规则（基于 hyprland 的 windowrulev2 配置）
      window-rules = [
        # 工作区分配规则（对应 hyprland 的 workspace 规则）
        {
          matches = [{app-id = "^${terminal}$";}];
          open-on-workspace = "1";
        }
        {
          matches = [{app-id = "^chromium-browser$";}];
          open-on-workspace = "2";
        }
        {
          matches = [{app-id = "^jetbrains-goland$";}];
          open-on-workspace = "3";
        }

        # 浮动窗口规则（niri 不需要浮动窗口，但可以设置特殊行为）
        {
          matches = [{app-id = "^org\\.pulseaudio\\.pavucontrol$";}];
          default-column-width = {proportion = 0.3;};
        }
        {
          matches = [{app-id = "^nm-connection-editor$";}];
          default-column-width = {proportion = 0.3;};
        }
      ];

      # 启动应用程序（基于 hyprland 的 exec-once 配置）
      spawn-at-startup = [
        # Fcitx5 输入法配置（对应 hyprland 的 fcitx5 配置）
        {command = ["bash" "-c" "cp ~/.config/fcitx5/profile-bak ~/.config/fcitx5/profile"];}
        {command = ["fcitx5" "-d" "--replace"];}

        # 剪贴板历史（DMS 需要）
        {command = ["bash" "-c" "wl-paste --watch cliphist store &"];}

        # Polkit 认证代理
        {command = ["/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"];}

        # 启动 xwayland-satellite 以支持 X11 应用（如 GoLand）
        {command = ["xwayland-satellite"];}
      ];

      # 快捷键绑定（基于 hyprland 的 bind 配置）
      #
      # 注意：DMS 会通过 niri.enableKeybinds 自动添加以下快捷键，请勿在此重复定义：
      # - Mod+Space: 应用启动器 (spotlight toggle)
      # - Mod+N: 通知中心 (notifications toggle)
      # - Mod+Comma: 设置 (settings toggle)
      # - Mod+P: 记事本 (notepad toggle)
      # - Super+Alt+L: 锁屏 (lock screen)
      # - Mod+X: 电源菜单 (powermenu toggle)
      # - Mod+M: 进程列表 (processlist toggle) - 仅当 enableSystemMonitoring = true
      # - Mod+V: 剪贴板管理器 (clipboard toggle) - 仅当 enableClipboard = true
      # - XF86AudioRaiseVolume/LowerVolume/Mute/MicMute: 音频控制
      # - XF86MonBrightnessUp/Down: 亮度控制 - 仅当 enableBrightnessControl = true
      # - Mod+Alt+N: 夜间模式 (night mode toggle) - 仅当 enableNightMode = true
      binds = with config.lib.niri.actions; {
        # 系统操作
        # 关闭当前窗口（对应 hyprland 的 $mod, q, killactive）
        "${mod}+Q".action = close-window;

        # 应用启动器 - 使用 fuzzel
        "${mod}+Space".action = spawn "fuzzel";

        # 终端和应用启动（对应 hyprland 的应用启动绑定）
        "${mod}+Return".action = spawn terminal;
        "${mod}+B".action = spawn browser;
        "${mod}+I".action = spawn IDE;

        # 工作区管理（对应 hyprland 的工作区切换）
        "${mod}+F1".action.focus-workspace = 1;
        "${mod}+F2".action.focus-workspace = 2;
        "${mod}+F3".action.focus-workspace = 3;
        "${mod}+F4".action.focus-workspace = 4;

        # 移动窗口到工作区（对应 hyprland 的 movetoworkspace）
        "${mod}+Shift+F1".action.move-column-to-workspace = 1;
        "${mod}+Shift+F2".action.move-column-to-workspace = 2;
        "${mod}+Shift+F3".action.move-column-to-workspace = 3;
        "${mod}+Shift+F4".action.move-column-to-workspace = 4;

        # 窗口焦点切换（对应 hyprland 的 movefocus）
        "${mod}+Left".action = focus-column-left;
        "${mod}+Right".action = focus-column-right;
        "${mod}+Up".action = focus-window-up;
        "${mod}+Down".action = focus-window-down;

        # 移动窗口（对应 hyprland 的 movewindow）
        "${mod}+Shift+Left".action = move-column-left;
        "${mod}+Shift+Right".action = move-column-right;
        "${mod}+Shift+Up".action = move-window-up;
        "${mod}+Shift+Down".action = move-window-down;

        # 调整窗口大小（对应 hyprland 的 resizeactive）
        "${mod}+Ctrl+Left".action.set-column-width = "-10%";
        "${mod}+Ctrl+Right".action.set-column-width = "+10%";
        "${mod}+Ctrl+Up".action.set-window-height = "-10%";
        "${mod}+Ctrl+Down".action.set-window-height = "+10%";

        # 全屏切换（对应 hyprland 的 fullscreen）
        "${mod}+F".action = fullscreen-window;

        # 最大化切换（niri 特有）
        # 注意：Mod+M 被 DMS 用于进程列表，这里使用 Mod+Shift+M
        "${mod}+Shift+M".action = maximize-column;

        # 指定区域截图
        # 注意没有 -c 和 -p，也没有使用 flameshot full 来直接截取全屏，以确保灵活性
        # 之前使用wayland内置的 grim + slurp，以及hyprland和niri内置截图工具，都不如flameshot好用
        "Print".action = spawn "sh" "-c" "flameshot gui";

        # 锁屏（对应 hyprland 的 swaylock）
        # 注意：Super+Alt+L 被 DMS 用于锁屏，这里使用 Ctrl+Alt+L 作为备用
        "Ctrl+Alt+L".action = spawn "swaylock";

        # 电源菜单
        # 注意：Mod+X 被 DMS 用于电源菜单，这里使用 Mod+Shift+X 作为备用
        "${mod}+Shift+X".action = spawn "wlogout";

        # 网络管理器（对应 hyprland 的 nm-connection-editor）
        # 注意：Mod+N 被 DMS 用于通知中心，这里使用 Mod+Shift+N
        "${mod}+Shift+N".action = spawn "nm-connection-editor";

        # Fcitx5 重启（对应 hyprland 的 fcitx5 重启绑定）
        "${mod}+E".action = spawn "bash" "-c" "pkill fcitx5 -9; sleep 1; fcitx5 -d --replace; sleep 1; fcitx5-remote -r";

        # 工作区滚动切换（对应 hyprland 的鼠标滚轮切换）
        "${mod}+WheelScrollDown".action = focus-workspace-down;
        "${mod}+WheelScrollUp".action = focus-workspace-up;

        # 消费或弹出窗口（niri 特有功能）
        # 注意：Mod+Comma 被 DMS 用于设置，这里使用 Mod+Period 和 Mod+Shift+Period
        "${mod}+Period".action = consume-window-into-column;
        "${mod}+Shift+Period".action = expel-window-from-column;

        # 切换窗口方向（niri 特有）
        "${mod}+R".action = switch-preset-column-width;
        "${mod}+Shift+R".action = reset-window-height;
      };

      # 手势配置（基于 hyprland 的 gestures 配置）
      # niri 的手势配置
      # 注意：niri 的手势系统与 hyprland 不同，这里保持默认配置
    };
  };

  # 启动 fcitx5 输入法（对应 hyprland 的 exec-once）
  # 这部分已经在 spawn-at-startup 中配置

  # NOTE: this executable is used by greetd to start a wayland session when system boot up
  # with such a vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS module
  home.file.".wayland-session" = {
    source = "${config.programs.niri.package}/bin/niri-session";
    executable = true;
  };
}
