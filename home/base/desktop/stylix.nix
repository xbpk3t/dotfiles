{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
with lib;
let
  isLinux = pkgs.stdenv.isLinux;
  cfg = config.modules.desktop.stylix;
in
{
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  options.modules.desktop.stylix = {
    enable = mkEnableOption "stylix theming";
  };

  config = mkIf cfg.enable {
    stylix = {
      enable = mkDefault true;

      autoEnable = mkDefault true;
      enableReleaseChecks = false;
      overlays.enable = false;
      # NOTE:
      # 当 HM 使用 useGlobalPkgs=true 时，stylix overlays 会写入 nixpkgs.overlays，
      # 触发 "nixpkgs.config/overlays with useGlobalPkgs" 警告。
      # 这里显式关闭 overlays，仅保留主题渲染能力。

      # Home Manager integration settings
      #    homeManagerIntegration = {
      #      autoImport = true;
      #      followSystem = true;
      #    };

      # 使用base00作为背景色（Gruvbox的深背景）
      #    image = config.lib.stylix.pixel "base00";
      #    image = pkgs.fetchurl {
      #      url = "https://cdn.lucc.dev/wallpapers/a1.png";
      #      hash = "sha256-NJy3pGK/I0bgmjT2Irxak3AX+8n4rHcFd2eNzC6RQtg=";
      #    };

      # 暗色主题
      polarity = "dark";

      # Color scheme configuration
      # https://nix-community.github.io/stylix/configuration.html#handmade-schemes
      # https://github.com/tinted-theming/schemes
      # 注意这里不接受 base24 的theme
      # Switch to Catppuccin Mocha for a dark, pastel-friendly palette
      # base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
      # base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-latte.yaml";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";

      # Font configuration
      fonts = {
        # Monospace font for terminals and code
        # 统一使用 JetBrainsMono Nerd Font，与 Ghostty 保持一致。
        # 注意：这里只影响 stylix 所覆盖的 GTK/Qt 应用外观，
        # 不涉及字体安装 —— 安装走 NixOS/darwin 的 fonts.packages。
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font Mono";
        };

        # UI文本 - 使用支持中文的字体
        # sansSerif = {
        #   # 苹果苹方作为默认 UI 字体
        #   package = pkgs.apple-pingfang;
        #   name = "PingFang SC";
        # };

        # # 正式文本（比如浏览器文本）- 使用支持中文的字体
        # serif = {
        #   package = pkgs.noto-fonts-cjk-serif;
        #   # Noto Serif CJK 作为 fallback
        #   name = "Noto Serif CJK SC";
        # };

        # # Emoji font - using noto-fonts-color-emoji for better compatibility
        # emoji = {
        #   package = pkgs.noto-fonts-color-emoji;
        #   name = "Noto Color Emoji";
        # };

        sizes = {
          # GUI 应用（Qt/GTK）+ 部分工具firefox, thunderbird, vscode, jetbrains.*, discord, slack, spotify
          # 按照firefox设置为13(好像这里控制不了firefox的font size)
          # zed 设置为13就太大了，所以设置为12
          applications = 12;
          # 所有 终端模拟器alacritty, kitty, wezterm, foot, contour
          terminal = 11;
          # 桌面环境 UI（面板、菜单、图标标签）plasma 面板、任务栏、菜单字体；gnome 顶部栏、概览；sway/hyprland bar
          desktop = 12;
          # 弹出菜单、通知、上下文菜单右键菜单、通知中心、rofi/dmenu、waybar 提示、文件管理器预览
          popups = 12;
        };
      };

      targets = {
        rofi.enable = false;
        zed.enable = false;
        # helix本身有内置theme，比stylix提供的要好很多
        helix.enable = false;

        # 配置 Firefox profile names 以避免 stylix warning
        firefox.profileNames = [ "default" ];
      }
      // optionalAttrs isLinux {
        qt = {
          enable = true;
          platform = "qtct";
        };
      };
      # 使用默认 cursor，但是改小size
      #    cursor = {
      ##      package = pkgs.bibata-cursors;
      ##      name = "Bibata-Modern-Classic";
      ##      size = 14;
      #
      #      #      package = pkgs.apple-cursor;
      #      #      name = "macOS-BigSur-White";
      #      #      size = 14;
      #    };
    };

    home.packages =
      with pkgs;
      optionals isLinux [
        apple-cursor
      ];
  };
}
