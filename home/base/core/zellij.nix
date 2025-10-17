_: {
  programs.zellij = {
    enable = true;

    settings = {
      # Basic behavior
      on_force_close = "quit";
      simplified_ui = false;
      default_layout = "default";
      default_shell = "zsh";
      default_mode = "normal";
      show_startup_tips = false;

      # Mouse support
      mouse_mode = true;
      advanced_mouse_actions = true;

      # Copy and paste
      copy_command = "pbcopy";
      copy_clipboard = "primary";

      # UI settings
      ui.pane_frames.rounded_corners = true;
      ui.pane_frames.hide_session_name = false;

      # Scroll buffer
      scroll_buffer_size = 10000;

      # Theme
      theme = "default";
    };

    # PLAN [2025-10-10] 补充 zellij 插件
    # [zellij-org/awesome-zellij: A list of awesome resources for zellij](https://github.com/zellij-org/awesome-zellij)
    # 需要安装以下插件：
    # room
    # 没有 keybinds 这个key
    #    keybinds = {
    #      normal = {
    #        bind = [
    #          {
    #            key = "Ctrl+f";
    #            command = "zellij plugin -- zellij:forgot";
    #          }
    #          {
    #            key = "Ctrl+o";
    #            command = "zellij plugin -- zellij:filepicker";
    #          }
    #        ];
    #      };
    #    };

    layouts = {
      default = {
        layout = {
          _children = [
            {
              default_tab_template = {
                _children = [
                  {
                    pane = {
                      size = 1;
                      borderless = true;
                      plugin = {
                        location = "zellij:tab-bar";
                      };
                    };
                  }
                  {
                    children = {};
                  }
                  {
                    pane = {
                      size = 2;
                      borderless = true;
                      plugin = {
                        location = "zellij:status-bar";
                      };
                    };
                  }

                  # filepicker 插件有问题，所以注释掉
                  #                  {
                  #                    pane = {
                  #                      size = 1;
                  #                      borderless = true;
                  #                      plugin = {
                  #                        location = "zellij:filepicker";
                  #                      };
                  #                    };
                  #                  }
                ];
              };
            }
            {
              tab = {
                _props = {
                  name = "Shell";
                  focus = true;
                };
                _children = [
                  {
                    pane = {
                      command = "zsh";
                    };
                  }
                ];
              };
            }
          ];
        };
      };
    };
  };

  # only works in bash/zsh, not nushell
  home.shellAliases = {
    "zz" = "zellij";
  };
}
