#_: {
#  programs.helix = {
#    enable = true;
#    defaultEditor = true;
#
#    settings = {
#      theme = "catppuccin_mocha";
#      editor = {
#        idle-timeout = 0;
#        completion-trigger-len = 1;
#        file-picker.hidden = false;
#        indent-guides.render = true;
#        color-modes = true;
#        cursor-shape = {
#          normal = "block";
#          insert = "bar";
#          select = "underline";
#        };
#
#        statusline = {
#          left = [
#            "mode"
#            "spinner"
#            "version-control"
#          ];
#          center = [
#            "file-base-name"
#            "file-modification-indicator"
#          ];
#          right = [
#            "diagnostics"
#            "position"
#            "file-encoding"
#            # "file-line-ending"
#            "file-type"
#          ];
#
#          mode = {
#            normal = "NORMAL";
#            insert = "INSERT";
#            select = "SELECT";
#          };
#        };
#        soft-wrap.enable = true;
#      };
#
#      keys = {
#        insert = {
#          "A-h" = "move_char_left";
#          "A-j" = "move_line_down";
#          "A-k" = "move_line_up";
#          "A-l" = "move_char_right";
#        };
#      };
#    };
#  };
#}
{...}: {
  #  programs.helix = with pkgs; {
  #    defaultEditor = true;
  #    extraPackages = [ inputs.nil ];
  #    settings = {
  #      theme = lib.mkForce "t_catppuccin_mocha";
  #      editor = {
  #        line-number = "relative";
  #
  #        lsp = {
  #          display-messages = true;
  #        };
  #        end-of-line-diagnostics = "hint";
  #        inline-diagnostics.cursor-line = "warning";
  #      };
  #      keys.insert = {
  #        C-backspace = "delete_word_backward";
  #      };
  #    };
  #    themes = {
  #      t_catppuccin_mocha = {
  #        inherits = "catppuccin_mocha";
  #        "ui.background" = { };
  #      };
  #    };
  #    languages = {
  #      language = [
  #        {
  #          name = "nix";
  #          auto-format = true;
  #          formatter.command = "${nixfmt}/bin/nixfmt";
  #          language-servers = [ "nil" ];
  #        }
  #        {
  #          name = "rust";
  #          auto-format = true;
  #          language-servers = [ "rust-analyzer" ];
  #        }
  #      ];
  #      language-server.rust-analyzer.config.check = {
  #        command = "clippy";
  #      };
  #      language-server.nil = {
  #        commands = "${inputs.nil}/bin/nil";
  #        config = { };
  #      };
  #    };
  #  };

  programs.helix = {
    enable = true;
    settings = {
      editor = {
        color-modes = true;
        bufferline = "multiple";

        #        clipboard = "system";  # 自动选择（推荐）

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        indent-guides = {
          render = true;
          character = "╎";
          skip-levels = 1;
        };
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        statusline = {
          left = ["mode" "spinner" "version-control"];
          center = ["read-only-indicator" "file-name"];
        };

        whitespace.render.tab = "all";
      };
      keys = {
        normal = {
          space.w = ":w";
          space.q = ":q";

          "Y" = ":clipboard-yank";
          "$" = {
            s = ":buffer-close";
            S = ":buffer-close!";
          };
        };
        select."Y" = ":clipboard-yank";
      };
    };
  };
}
