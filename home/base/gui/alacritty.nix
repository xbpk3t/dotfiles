{pkgs, ...}: {
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;

    settings = {
      terminal = {
        shell = {
          program = "${pkgs.zsh}/bin/zsh";
          args = [
            "-c"
            "${pkgs.zellij}/bin/zellij"
          ];
        };
      };

      window = {
        padding = {
          x = 4;
          y = 8;
        };
        decorations = "full";
        startup_mode = "Windowed";
        dynamic_title = true;
        option_as_alt = "Both";
      };
      cursor = {
        style = "Block";
      };

      # 键盘快捷键配置
      # keyboard.bindings = [
      #   # 使用 Super+C 复制选中文本到剪贴板
      #   {
      #     key = "C";
      #     mods = "Super";
      #     action = "Copy";
      #   }
      #   # 使用 Super+V 从剪贴板粘贴
      #   {
      #     key = "V";
      #     mods = "Super";
      #     action = "Paste";
      #   }
      #   # 禁用原 Ctrl+Shift+C/V（可选）
      #   {
      #     key = "C";
      #     mods = "Control|Shift";
      #     action = "None";
      #   }
      #   {
      #     key = "V";
      #     mods = "Control|Shift";
      #     action = "None";
      #   }
      # ];

      # 复制时自动保存到系统剪贴板
      selection.save_to_clipboard = true;
    };
  };
}
