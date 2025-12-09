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

    defaultEditor = true;

    settings = {
      editor = {
        color-modes = true;
        bufferline = "multiple";

        #        clipboard = "system";  # 自动选择（推荐）

        # soft-wrap = true;

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

        idle-timeout = 0;
        completion-trigger-len = 1;

        line-number = "relative";

        file-picker.hidden = false;

        end-of-line-diagnostics = "hint";
        inline-diagnostics.cursor-line = "warning";
        soft-wrap = {
          enable = true;
          # 下面这些可选，根据自己喜好开：
          # max-wrap = 25;
          # max-indent-retain = 0;
          # wrap-indicator = "";
        };

        # ------ 自动保存（auto-save）------
        # Helix 新版已经支持自动保存，包括“延时保存”和“失去焦点时保存”:contentReference[oaicite:0]{index=0}
        auto-save = {
          # 失去终端焦点时保存（切到别的窗口 / 切桌面等）
          focus-lost = true;

          # 修改后一段时间自动保存
          after-delay = {
            enable = true;
            # 毫秒：3000 = 3 秒
            timeout = 3000;
          };
        };
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
