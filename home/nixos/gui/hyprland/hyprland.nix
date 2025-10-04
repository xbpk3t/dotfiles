{pkgs, ...}: let
  package = pkgs.hyprland;

  # 变量定义 - keyd 映射后物理 Alt 键变成了 Super
  mod = "SUPER"; # keyd 映射：物理Alt → Super，所以用 SUPER
  # files = "thunar";

  files = "yazi";
  browser = "chromium";
  terminal = "foot";
  menu = "vicinae";
  menuZ = "anyrun";
in {
  # 所有配置已经直接整合到 settings 中，不再需要 xdg.configFile 引用

  # NOTE:
  # We have to enable hyprland/i3's systemd user service in home-manager,
  # so that gammastep/wallpaper-switcher's user service can be start correctly!
  # they are all depending on hyprland/i3's user graphical-session
  wayland.windowManager.hyprland = {
    inherit package;
    enable = true;
    settings = {
      # 变量定义 - 直接在 Hyprland 中使用
      "$mod" = mod;
      "$files" = files;
      "$browser" = browser;

      # === 启动应用程序 (exec.conf) ===
      # ============================================================================

      # 修复 anyrun 的链接问题
      # 参考: https://github.com/anyrun-org/anyrun/issues/153
      exec-once = [
        "ln -s \"$XDG_RUNTIME_DIR/hypr\" /tmp/hypr"

        # Fcitx5 输入法配置
        "cp ~/.config/fcitx5/profile-bak ~/.config/fcitx5/profile" # 恢复由 nixos 管理的 fcitx5 profile
        "fcitx5 -d --replace" # 启动 fcitx5 守护进程

        # 终端和应用启动
        "wezterm" # 默认启动的终端
        "${browser}" # 浏览器
        "goland" # IDE

        # 工作区切换
        "sleep 3; hyprctl dispatch workspace 1"
        "sleep 3; hyprctl dispatch workspace 4"
      ];

      # 系统相关键绑定
      # ============================================================================

      # 拖拽窗口
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # 所有键绑定统一配置
      # ============================================================================

      bind = [
        # === 系统操作 ===
        # 关闭当前窗口
        "$mod, q, killactive"

        # 终端启动器（注意：keyd映射后物理Alt键现在作为Super使用）
        "$mod, Return, exec, ${terminal}"
        "$mod, d, exec, ${menu}"
        # [[Feature request] A way to close the prompt with a command? · Issue #103 · anyrun-org/anyrun](https://github.com/anyrun-org/anyrun/issues/103)
        "$mod, z, exec, pgrep ${menuZ} && pkill ${menuZ} || ${menuZ}"

        # 硬件控制 - 使用 WirePlumber 进行音频控制
        # 参考: https://wiki.archlinux.org/title/WirePlumber
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86Search, exec, ${menu}"

        # === 工作区快捷切换 ===
        # 切换工作区（如果该工作区没有目标应用，则启动它）
        "$mod, 1, exec, if [ $(hyprctl clients -j | jq 'map(select(.workspace.id == 1)) | length') -eq 0 ]; then wezterm; fi; hyprctl dispatch workspace 1"
        "$mod, 2, exec, if [ $(hyprctl clients -j | jq 'map(select(.workspace.id == 2)) | length') -eq 0 ]; then firefox; fi; hyprctl dispatch workspace 2"
        "$mod, 3, exec, if [ $(hyprctl clients -j | jq 'map(select(.workspace.id == 3)) | length') -eq 0 ]; then goland; fi; hyprctl dispatch workspace 3"

        # === 工作区管理 ===
        # 使用功能键切换工作区
        "$mod, F1, workspace, 1"
        "$mod, F2, workspace, 2"
        "$mod, F3, workspace, 3"
        "$mod, F4, workspace, 4"

        # 移动窗口到指定工作区
        "$mod SHIFT, F1, movetoworkspace, 1"
        "$mod SHIFT, F2, movetoworkspace, 2"
        "$mod SHIFT, F3, movetoworkspace, 3"
        "$mod SHIFT, F4, movetoworkspace, 4"

        # 鼠标滚轮切换工作区
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # === 窗口管理 ===
        # 移动窗口
        "$mod SHIFT, left, movewindow, l"
        "$mod SHIFT, right, movewindow, r"
        "$mod SHIFT, up, movewindow, u"
        "$mod SHIFT, down, movewindow, d"

        # 窗口焦点切换
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # 调整窗口大小
        "$mod CTRL, left, resizeactive, -20 0"
        "$mod CTRL, right, resizeactive, 20 0"
        "$mod CTRL, up, resizeactive, 0 -20"
        "$mod CTRL, down, resizeactive, 0 20"

        # === 模式切换 ===
        "$mod SHIFT, d, submap, mode_displays"
        "$mod SHIFT, a, submap, mode_move"
        "$mod, r, submap, mode_resize"
        "$mod SHIFT, s, submap, mode_screenshot"
        "$mod SHIFT, e, submap, mode_shutdown"

        # === 布局控制 ===
        # 切换浮动窗口
        "$mod, space, togglefloating"
        # 切换全屏
        "$mod, f, fullscreen"
        # 其他布局选项（当前注释）
        # "$mod, s, layout stacking"
        # "$mod, w, layout tabbed"
        # "$mod, e, layout toggle split"

        # === 截图和系统操作 ===
        # 截图功能
        ", Print, exec, hyprshot -m output -o ~/Pictures/Screenshots -- imv"
        "$mod, Print, exec, hyprshot -m window -o ~/Pictures/Screenshots -- imv"
        "CTRL, Print, exec, hyprshot -m region -o ~/Pictures/Screenshots"

        # 其他系统操作
        "CTRL ALT, l, exec, swaylock"
        "$mod SHIFT, x, exec, wlogout"
        "$mod, n, exec, nm-connection-editor" # 需要安装 network-manager-applet

        # === Fcitx5 输入法控制 (fcitx5.conf) ===
        # 重启 fcitx5 输入法
        "$mod, E, exec, pkill fcitx5 -9;sleep 1;fcitx5 -d --replace; sleep 1;fcitx5-remote -r"
      ];

      # 手势支持 (Hyprland 0.51+)
      # ============================================================================
      # 格式: gesture = <fingers>, <direction>, <action>
      # 参考: https://wiki.hyprland.org/Configuring/Gestures/

      gesture = [
        # 四指水平滑动切换工作区
        "4, horizontal, workspace"
        # 三指滑动（可选，当前注释）
        # "3, horizontal, workspace"
      ];

      # === 设置和配置 (settings.conf) ===
      # ============================================================================

      # 拖拽和点击设置
      binds = {
        drag_threshold = 5; # 降低到 5px，更容易触发拖拽
      };

      # 窗口和边框设置
      general = {
        layout = "dwindle";

        # 光标设置
        no_focus_fallback = true;

        # 间距设置
        gaps_in = 5;
        gaps_out = 5;

        # 边框设置
        border_size = 0;
        "col.active_border" = "0x00000000";
        "col.inactive_border" = "0x00000000";

        # 调整设置
        resize_on_border = false;
        hover_icon_on_border = false;

        # 允许撕裂（需要添加窗口规则到要允许撕裂的窗口）
        allow_tearing = false;
      };

      cursor = {
        inactive_timeout = 900; # 在 n 毫秒后隐藏光标（在屏幕锁定时也有效）
        no_warps = false; # 永不自动移动光标
      };

      ecosystem = {
        no_donation_nag = true;
        no_update_news = true;
      };

      misc = {
        # 允许窗口窃取焦点 -（目前只有 xorg 应用程序）
        focus_on_activate = false;

        # 如果使用个性化壁纸，则启用
        disable_hyprland_logo = true;
      };

      # 视觉效果设置
      # 参考: https://wiki.hyprland.org/Configuring/Variables
      decoration = {
        # 圆角边框
        rounding = 8;

        # 阴影设置
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        "active_opacity" = 1.0;
        "inactive_opacity" = 0.9;
        "fullscreen_opacity" = 1.0;

        blur = {
          enabled = true;
          new_optimizations = true;
          size = 3; # 最小为 1
          passes = 1; # 最小为 1，更多通道 = 更多资源密集
          ignore_opacity = false;
        };
      };

      # 动画设置
      # 参考: https://wiki.hyprland.org/Configuring/Animations
      animations = {
        enabled = true;

        # 贝塞尔曲线    NAME        X0    Y0   X1   Y1
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        # 动画配置 - 在 Nix 中需要使用列表格式
        animation = [
          "windows, 1, 2, myBezier"
          "windowsOut, 1, 2, default, popin 80%"
          "border, 1, 5, default"
          "fadeIn, 1, 2, default"
          "fadeOut, 1, 2, default"
          "workspaces, 1, 6, default, fade"
          "specialWorkspace, 1, 3, myBezier, slide"
        ];
      };

      # 布局细节
      # 参考: https://wiki.hyprland.org/Configuring/Dwindle-Layout/
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # 参考: https://wiki.hyprland.org/Configuring/Master-Layout
      master = {
        new_on_top = true;
      };

      # 手势配置 - 优化以减少与文本选择的冲突
      # 改为 4 指手势用于工作区切换，避免与 3 指文本选择冲突
      gestures = {
        workspace_swipe_distance = 300;
        workspace_swipe_touch = false;
        workspace_swipe_invert = true;
        workspace_swipe_touch_invert = false;
        workspace_swipe_min_speed_to_force = 30;
        workspace_swipe_cancel_ratio = 0.5;
        workspace_swipe_create_new = true;
        workspace_swipe_direction_lock = true;
        workspace_swipe_direction_lock_threshold = 10;
        workspace_swipe_forever = false;
        workspace_swipe_use_r = false;
      };

      # 输入设置 - 配置鼠标和触摸板
      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        # 鼠标焦点不会切换到悬停的窗口，除非鼠标跨越窗口边界
        follow_mouse = 1;
        mouse_refocus = false;

        natural_scroll = 0;
        touchpad = {
          natural_scroll = 1;
          # 滚动速度设置 - 调整这个值来改变上下滑动速度
          # 大于 1.0 加速滚动，小于 1.0 减速滚动
          # 大家普遍设置为0.2，但是我的touchpad比较小所以设置为0.4
          scroll_factor = 0.4;

          # 关键设置：启用点击行为模式，这样可以用手指数量而不是位置来区分点击
          clickfinger_behavior = true;
          disable_while_typing = true;
          # 轻触触摸板点击功能 - 对于物理按压触控板仍然重要
          tap-to-click = true;
          tap-and-drag = true;
          # 重要：启用拖拽锁定，这样松开手指后拖拽不会立即停止
          drag_lock = 2; # 2 = sticky mode，最适合文本选择
          # 中键点击模拟 - 保持启用，可能有用
          middle_button_emulation = true;
          # 三指拖拽功能 - 启用三指拖拽，用于文本选择
          drag_3fg = 1;
          # 点击映射设置 - 在 clickfinger_behavior 下工作方式不同
          tap_button_map = "lmr";
        };
        force_no_accel = 0;
        numlock_by_default = 1;
      };

      # 显示器设置
      monitor = ", preferred, auto, 1";

      # === 窗口规则 (windowrules.conf) ===
      # ============================================================================

      # 使用 'hyprctl clients' 发现类名
      # 参考: https://wiki.hyprland.org/Configuring/Window-Rules/

      # 工作区分配规则
      # ============================================================================
      windowrulev2 = [
        # 终端 - alacritty在工作区1
        "workspace 1, class:^(wezterm)$"

        # 浏览器
        "workspace 2, class:^(chromium-browser)$"

        # IDE - Goland可能的类名
        "workspace 3, class:^(goland)$"

        # 浮动窗口
        "float, class:^(pulsemixer)$"
        "float, class:^(org.pulseaudio.pavucontrol)$"
        "float, class:^(nm-connection-editor)$"
        "float, class:^(feh|imv|Gpicview)$"
        "float, title:^(File Transfer*)$"
        "float, title:^(Save File)$"
        "float, class:^(blueman-manager)$"
        "float, class:^(thunderbird)$, title:^(.*Reminder)"

        # Fcitx5 输入法 - 启用此选项可以使 fcitx5 工作，但 fcitx5-configtool 将不工作！
        "pseudo, class:^(fcitx)$"

        # Steam 修复
        "stayfocused, title:^()$, class:^(steam)$"
        "minsize 1 1, title:^()$, class:^(steam)$"
        "tile, class:^(steam)$"
        "fullscreen, class:^(steam)$"

        # wlogout
        "float, class:^(wlogout)$"
        "move 0 0, class:^(wlogout)$"
        "size 100% 100%, class:^(wlogout)$"
        "animation slide, class:^(wlogout)$"
      ];

      env = [];
    };
    # gammastep/wallpaper-switcher need this to be enabled.
    systemd = {
      enable = true;
      variables = ["--all"];
    };
  };

  # NOTE: this executable is used by greetd to start a wayland session when system boot up
  # with such a vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS module
  home.file.".wayland-session" = {
    source = "${package}/bin/Hyprland";
    executable = true;
  };
}
