{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.labwc;
in {
  options.modules.desktop.labwc = {
    enable = lib.mkEnableOption "labwc compositor";
  };

  config = lib.mkIf cfg.enable {
    # 安装必要的包
    home.packages = with pkgs; [
      # Wayland相关工具
      swaybg # 壁纸
      wl-clipboard # 剪贴板
      wlogout # 电源菜单
      swaylock # 锁屏
      brightnessctl # 亮度控制

      # 截图工具
      flameshot

      # 窗口管理工具
      wtype # 用于发送键盘事件
      wlrctl # Wayland compositor control

      # 其他工具
      xdg-utils
      pulseaudio # pactl命令
    ];

    # Add the focus-or-spawn script
    home.file.".local/bin/focus-or-spawn".text = ''
      #!/bin/sh
      # Generic script for focus-or-spawn functionality on Wayland
      # Usage: focus-or-spawn.sh <process_name> <launch_command>

      process_name="$1"
      launch_command="$2"

      case "$process_name" in
          "alacritty")
              # For terminal applications, we can check if any alacritty process is running
              if pgrep -x "alacritty" > /dev/null; then
                  # On Wayland, focusing is limited, so we'll just ensure it's running
                  # Optionally, we could launch a new instance to bring it to attention
                  $launch_command &
              else
                  $launch_command &
              fi
              ;;
          "firefox")
              # For Firefox, check if it's running
              if pgrep -x "firefox" > /dev/null; then
                  # Could try to open a new window or just ensure it's running
                  $launch_command &
              else
                  $launch_command &
              fi
              ;;
          "goland")
              # For Goland, check if it's running (using a partial match)
              if pgrep -f "goland" > /dev/null; then
                  $launch_command &
              else
                  $launch_command &
              fi
              ;;
          *)
              # Default case: check if process is running and either focus or spawn
              if pgrep -f "$process_name" > /dev/null; then
                  $launch_command &
              else
                  $launch_command &
              fi
              ;;
      esac
    '';
    home.file.".local/bin/focus-or-spawn".executable = true;

    # Wayland 环境变量
    home.sessionVariables = {
      # 禁用 GDK 的 DPI 缩放，让 compositor 处理
      GDK_DPI_SCALE = "1.0";
      # 确保 Qt 应用使用 Wayland
      QT_QPA_PLATFORM = "wayland";
    };

    # Labwc compositor 配置
    wayland.windowManager.labwc = {
      enable = true;

      # 自动启动程序
      autostart = [
        # Stylix 壁纸
        "swaybg -i ${config.stylix.image} -m fill"
        # Fcitx5 输入法
        "fcitx5 -d --replace"
        # Polkit 认证代理
        "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1"
      ];

      # 环境变量
      environment = [
        # "WAYLAND_DISPLAY=wayland-1"
      ];

      # 使用 rc 选项配置 labwc (符合 home-manager 的推荐方式)
      rc = {
        # 核心设置
        core = {
          "@decoration" = "server";
          "@gap" = "0";
          "@adaptiveSync" = "no";
        };

        # 主题设置
        theme = {
          "@name" = "Adapta-Nokto";
          "@cornerRadius" = "8";
          font = {
            "@place" = "ActiveWindow";
            "@name" = "Sans";
            "@size" = "11";
            "@slant" = "normal";
            "@weight" = "bold";
          };
        };

        # 键盘设置
        keyboard = {
          "@numlock" = "on";
          "@layoutName" = "us";
          "@repeatRate" = "25";
          "@repeatDelay" = "600";

          # 系统操作
          keybind = [
            {
              "@key" = "W-q";
              action = {
                "@name" = "Close";
              };
            }

            # 终端和应用启动 (using number keys 1, 2, 3 with focus-or-spawn)
            {
              "@key" = "W-1";
              action = {
                "@name" = "Execute";
                "@command" = "bash";
                "@arguments" = "-c \"${config.home.homeDirectory}/.local/bin/focus-or-spawn alacritty alacritty\"";
              };
            }
            {
              "@key" = "W-2";
              action = {
                "@name" = "Execute";
                "@command" = "bash";
                "@arguments" = "-c \"${config.home.homeDirectory}/.local/bin/focus-or-spawn firefox firefox\"";
              };
            }
            {
              "@key" = "W-3";
              action = {
                "@name" = "Execute";
                "@command" = "bash";
                "@arguments" = "-c \"${config.home.homeDirectory}/.local/bin/focus-or-spawn goland goland\"";
              };
            }

            # Rofi 启动器
            {
              "@key" = "W-d";
              action = {
                "@name" = "Execute";
                "@command" = "rofi -show combi";
              };
            }
            {
              "@key" = "W-space";
              action = {
                "@name" = "Execute";
                "@command" = "rofi -show combi";
              };
            }

            # 窗口切换 - Alt+Tab (labwc原生支持)
            {
              "@key" = "A-Tab";
              action = {
                "@name" = "NextWindow";
              };
            }
            {
              "@key" = "A-S-Tab";
              action = {
                "@name" = "PreviousWindow";
              };
            }
            # 窗口切换 - Mod+Tab (Win key + Tab)
            {
              "@key" = "W-Tab";
              action = {
                "@name" = "NextWindow";
              };
            }
            {
              "@key" = "W-S-Tab"; # Mod+Shift+Tab for previous window
              action = {
                "@name" = "PreviousWindow";
              };
            }

            # 音量控制 - F2/F3 (用户自定义)
            {
              "@key" = "F2";
              action = {
                "@name" = "Execute";
                "@command" = "pactl set-sink-volume @DEFAULT_SINK@ -10%";
              };
            }
            {
              "@key" = "F3";
              action = {
                "@name" = "Execute";
                "@command" = "pactl set-sink-volume @DEFAULT_SINK@ +10%";
              };
            }

            # 媒体键
            {
              "@key" = "XF86AudioRaiseVolume";
              action = {
                "@name" = "Execute";
                "@command" = "pactl set-sink-volume @DEFAULT_SINK@ +5%";
              };
            }
            {
              "@key" = "XF86AudioLowerVolume";
              action = {
                "@name" = "Execute";
                "@command" = "pactl set-sink-volume @DEFAULT_SINK@ -5%";
              };
            }
            {
              "@key" = "XF86AudioMute";
              action = {
                "@name" = "Execute";
                "@command" = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
              };
            }

            # 亮度控制
            {
              "@key" = "XF86MonBrightnessUp";
              action = {
                "@name" = "Execute";
                "@command" = "brightnessctl set +5%";
              };
            }
            {
              "@key" = "XF86MonBrightnessDown";
              action = {
                "@name" = "Execute";
                "@command" = "brightnessctl set -5%";
              };
            }

            # 窗口焦点切换
            {
              "@key" = "W-Left";
              action = {
                "@name" = "MoveToEdge";
                "@direction" = "left";
              };
            }
            {
              "@key" = "W-Right";
              action = {
                "@name" = "MoveToEdge";
                "@direction" = "right";
              };
            }
            {
              "@key" = "W-Up";
              action = {
                "@name" = "MoveToEdge";
                "@direction" = "up";
              };
            }
            {
              "@key" = "W-Down";
              action = {
                "@name" = "MoveToEdge";
                "@direction" = "down";
              };
            }

            # 全屏切换
            {
              "@key" = "W-f";
              action = {
                "@name" = "ToggleFullscreen";
              };
            }

            # 最大化切换
            {
              "@key" = "W-S-m";
              action = {
                "@name" = "ToggleMaximize";
              };
            }

            # 截图
            {
              "@key" = "Print";
              action = {
                "@name" = "Execute";
                "@command" = "flameshot gui";
              };
            }

            # 锁屏
            {
              "@key" = "C-A-l";
              action = {
                "@name" = "Execute";
                "@command" = "swaylock";
              };
            }

            # 电源菜单
            {
              "@key" = "W-S-x";
              action = {
                "@name" = "Execute";
                "@command" = "wlogout";
              };
            }

            # Fcitx5 重启
            {
              "@key" = "W-e";
              action = {
                "@name" = "Execute";
                "@command" = "bash -c \"pkill fcitx5 -9; sleep 1; fcitx5 -d --replace; sleep 1; fcitx5-remote -r\"";
              };
            }

            # 窗口移动
            {
              "@key" = "W-S-Left";
              action = {
                "@name" = "MoveToEdge";
                "@direction" = "left";
              };
            }
            {
              "@key" = "W-S-Right";
              action = {
                "@name" = "MoveToEdge";
                "@direction" = "right";
              };
            }
            {
              "@key" = "W-S-Up";
              action = {
                "@name" = "MoveToEdge";
                "@direction" = "up";
              };
            }
            {
              "@key" = "W-S-Down";
              action = {
                "@name" = "MoveToEdge";
                "@direction" = "down";
              };
            }
          ];
        };

        # 鼠标设置
        mouse = {
          "@default" = "";
        };

        # Libinput 触摸板设置
        libinput = {
          device = [
            {
              "@category" = "touchpad";
              "@naturalScroll" = "yes";
              "@tap" = "yes";
              "@tapButtonMap" = "lrm";
              "@disableWhileTyping" = "yes";
              "@accelSpeed" = "0.0";
              "@accelProfile" = "flat";
              "@clickMethod" = "clickfinger";
              "@scrollFactor" = "0.2";
            }
            {
              "@category" = "pointer";
              "@accelSpeed" = "0.0";
              "@accelProfile" = "flat";
            }
          ];
        };

        # 焦点设置
        focus = {
          "@followMouse" = "yes";
          "@raiseOnFocus" = "yes";
        };

        # 窗口规则 - 所有窗口默认最大化
        windowRules = {
          windowRule = {
            action = {
              "@name" = "maximize";
            };
          };
        };
      };
    };

    # XDG Portal 配置
    xdg.portal = {
      enable = true;
      config = {
        common = {
          default = ["gtk" "wlr"];
        };
      };
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
      ];
    };

    # NOTE: this executable is used by greetd to start a wayland session when system boot up
    home.file.".wayland-session" = {
      text = ''
        #!/bin/sh
        exec labwc
      '';
      executable = true;
    };
  };
}
