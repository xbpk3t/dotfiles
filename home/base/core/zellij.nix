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
    "jj" = "zellij";
  };
}
