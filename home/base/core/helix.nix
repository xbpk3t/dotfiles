{pkgs, ...}: {
  # https://github.com/usagi-flow/evil-helix
  # https://mynixos.com/nixpkgs/package/evil-helix

  # https://mynixos.com/home-manager/options/programs.helix
  programs.helix = {
    enable = true;
    defaultEditor = true;

    extraPackages = [pkgs.marksman];

    settings = {
      # https://docs.helix-editor.com/master/editor.html
      editor = {
        color-modes = true;
        bufferline = "multiple";

        # 不需要配置，应该让helix自动检测剪贴板（以适应不同OS，比如说 mac上应设置 pasteboard，而linux则应该设置为 wayland, x-clip 之类的。就很麻烦，没必要）
        # clipboard-provider = "system";

        soft-wrap = {
          enable = true;
          # 下面这些可选，根据自己喜好开：
          # max-wrap = 25;
          # max-indent-retain = 0;
          # wrap-indicator = "";
        };

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

          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
        };

        whitespace.render.tab = "all";

        idle-timeout = 0;
        completion-trigger-len = 1;
        line-number = "relative";
        file-picker.hidden = false;

        end-of-line-diagnostics = "hint";
        inline-diagnostics.cursor-line = "warning";

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
        insert = {
          "A-h" = "move_char_left";
          "A-j" = "move_line_down";
          "A-k" = "move_line_up";
          "A-l" = "move_char_right";
        };
      };
    };

    languages = {
      language = [
        {
          name = "rust";
          auto-format = true;
          language-servers = ["rust-analyzer"];
        }
      ];
      language-server.rust-analyzer.config.check = {
        command = "clippy";
      };
    };
  };
}
