{ config, ... }:
let
  lspPackages = config.modules.langs.lsp.packages;
in
{

  programs.helix = {
    enable = true;
    defaultEditor = true;

    extraPackages = lspPackages;

    settings = {
      theme = "monokai";

      editor = {
        # 启用 true color（终端颜色正确渲染）
        true-color = true;
        color-modes = true;
        bufferline = "multiple";

        # 不需要配置，应该让helix自动检测剪贴板（以适应不同OS，比如说 mac上应设置 pasteboard，而linux则应该设置为 wayland, x-clip 之类的。就很麻烦，没必要）
        # clipboard-provider = "system";

        soft-wrap = {
          enable = true;
          wrap-at-text-width = true;
          # 下面这些可选，根据自己喜好开：
          # max-wrap = 25;
          # max-indent-retain = 0;
          # wrap-indicator = "";
        };

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        # 左侧边栏：diff 变更 | 诊断 | 行号 | 间隔
        gutters = {
          layout = [
            "diff"
            "diagnostics"
            "line-numbers"
            "spacer"
          ];
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
          left = [
            "mode"
            "spinner"
            "version-control"
          ];
          center = [
            "file-base-name"
            "file-modification-indicator"
          ];
          right = [
            "diagnostics"
            "position"
            "file-encoding"
            # "file-line-ending"
            "file-type"
          ];
          separator = "│";

          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };

        whitespace = {
          render.tab = "all";
          characters = {
            tab = "→";
            newline = "¶";
            space = "·";
          };
        };

        idle-timeout = 0;
        completion-trigger-len = 1;
        line-number = "relative";
        # 光标始终居中，无需手动滚屏
        scrolloff = 99999;
        file-picker.hidden = false;
        file-picker.ignore = false;

        end-of-line-diagnostics = "hint";
        inline-diagnostics.cursor-line = "warning";

        # ------ 自动保存（auto-save）------
        # Helix 新版已经支持自动保存，包括"延时保存"和"失去焦点时保存":contentReference[oaicite:0]{index=0}
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

        # P0 新增：视觉/行为增强
        cursorline = true;
        rulers = [ 80 ];
        default-line-ending = "lf";
        auto-info = true;
      };
      keys = {
        normal = {
          space = {
            w = ":w";
            q = ":quit!";
            Q = ":write-quit-all";
            f = ":buffer-close!";
            A-f = ":toggle auto-format";
            "." = ":toggle file-picker.git-ignore";
          };

          "Y" = ":clipboard-yank";

          "b" = ":buffer-close";

          left = "goto_previous_buffer";
          right = "goto_next_buffer";

          # gg 系：文件首/尾
          g = {
            j = "goto_file_end";
            k = "goto_file_start";
          };

          # G 跳到最后一行
          "G" = "goto_last_line";

          "#" = "toggle_comments";
          c = "change_selection_noyank";
          d = "delete_selection_noyank";
          A-d = "delete_selection";

          tab = "move_parent_node_end";
          S-tab = "move_parent_node_start";

          N = "extend_search_next";
          A-n = "search_prev";
          A-N = "extend_search_prev";

          C-d = [
            "page_cursor_half_down"
            "align_view_center"
          ];
          C-u = [
            "page_cursor_half_up"
            "align_view_center"
          ];
          C-j = [
            "extend_to_line_bounds"
            "delete_selection"
            "paste_after"
          ];
          C-k = [
            "extend_to_line_bounds"
            "delete_selection"
            "move_line_up"
            "paste_before"
          ];
        };
        select = {
          "Y" = ":clipboard-yank";
          tab = "extend_parent_node_end";
          S-tab = "extend_parent_node_start";
          # select mode 自动继承 normal 键位，g j / g k 已在 normal 定义
        };
        insert = {
          # 双击 j 退回 normal 模式（替代之前的 jk 非法绑定）
          j = {
            j = "normal_mode";
          };
          "A-h" = "move_char_left";
          "A-j" = "move_line_down";
          "A-k" = "move_line_up";
          "A-l" = "move_char_right";

          C-w = [
            "move_prev_word_start"
            "delete_selection_noyank"
          ];
          C-u = [
            "extend_to_line_bounds"
            "delete_selection_noyank"
            "open_above"
          ];
          C-space = "completion";
          S-tab = "move_parent_node_start";
        };
      };
    };

    languages = {
      language = [
        {
          name = "rust";
          auto-format = true;
          language-servers = [ "rust-analyzer" ];
        }
        {
          name = "nix";
          formatter = {
            command = "nixpkgs-fmt";
          };
          auto-format = true;
        }
        {
          name = "go";
          language-servers = [ "gopls" ];
          formatter = {
            command = "gofmt";
          };
          auto-format = true;
        }
        {
          name = "markdown";
          language-servers = [ "marksman" ];
          formatter = {
            command = "hongdown";
            args = [
              "--line-width=120"
              "--stdin"
            ];
          };
          auto-format = true;
        }
        {
          name = "yaml";
          language-servers = [ "yaml-language-server" ];
          formatter = {
            command = "prettier";
            args = [
              "--stdin-filepath"
              "%{buffer_name}"
            ];
          };
          auto-format = true;
        }
        {
          name = "json";
          language-servers = [
            {
              name = "vscode-json-language-server";
              except-features = [ "format" ];
            }
          ];
          auto-format = true;
        }
        {
          name = "jsonc";
          language-servers = [
            {
              name = "vscode-json-language-server";
              except-features = [ "format" ];
            }
          ];
          file-types = [
            "jsonc"
            "hujson"
          ];
          auto-format = true;
        }
        {
          name = "toml";
          language-servers = [ "taplo" ];
          auto-format = true;
        }
        {
          name = "sql";
          formatter = {
            command = "sql-formatter";
            args = [
              "-l"
              "postgresql"
              "-c"
              "{\"keywordCase\": \"lower\", \"dataTypeCase\": \"lower\", \"functionCase\": \"lower\", \"expressionWidth\": 120, \"tabWidth\": 4}"
            ];
          };
          auto-format = true;
        }
      ];
      language-server.rust-analyzer.config.check = {
        command = "clippy";
      };
    };
  };
}
