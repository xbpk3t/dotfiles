{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.ghostty;
in {
  options.modules.desktop.ghostty = {
    enable = mkEnableOption "ghostty terminal";
  };

  # [2026-01-22] [Scrolling issues · ghostty-org/ghostty · Discussion #7630](https://github.com/ghostty-org/ghostty/discussions/7630) 本地多次触发类似问题，本想换到其他Terminal，但是这个issue在其他terminal也是存在的，所以作罢。
  #
  # why?
  #
  # ***偶发进入 alternate screen（备用屏） 后，备用屏没有 scrollback，Ghostty（以及很多终端）会把“滚轮滚动”翻译成“↑/↓”来“让不支持鼠标的 TUI 也能滚动/导航”，结果在 shell 里就变成“翻历史/触发 atuin”。***
  #
  #
  #
  # 那其他terminal是否会遇到类似问题？
  #
  # 这类问题不是 Ghostty 独有，而是“终端生态里一个很常见的交互坑”，只是在不同 terminal 上触发条件/表现/可配置项不一样。
  # - 有的终端明确提供开关：比如 iTerm2 有“滚轮在 alternate screen 时发送方向键”的选项，开了就很容易出现你这种现象。
  # - 有的终端默认更“保守”：比如 kitty 通常更倾向于保持滚轮是滚动 scrollback（除非进入某些鼠标报告模式/你自己做了 mouse_map），所以更不容易踩到“滚轮=↑”。
  # - 有的终端遇到备用屏会更激进地“把滚轮喂给应用”：这样 TUI 的滚动体验更统一，但一旦状态没退出干净，就会在 shell 里造成“滚轮变按键”。
  #
  #
  #
  #
  # htu?
  # 在ghostty执行Reset操作（重置终端状态，常用于退出卡住的 alternate screen 状态）
  #
  #
  config = mkIf cfg.enable {
    # https://mynixos.com/home-manager/options/programs.ghostty
    # https://mynixos.com/nixpkgs/package/ghostty
    programs.ghostty = {
      # https://github.com/NixOS/nixpkgs/issues/388984
      enable = pkgs.stdenv.isLinux;
      # !!! On macOS the nixpkgs derivation is unsupported; allow Homebrew Cask to supply the app.
      # 注意 darwin 下直接使用brew安装ghostty，但是如果要做条件化判断，会比较麻烦，所以直接写到 brew.nix 里
      # 注意mac上使用brew（因为hm不支持）安装 ghostty，而非 alacritty
      package = pkgs.ghostty;

      installVimSyntax = true;
      installBatSyntax = true;
      enableZshIntegration = true;

      settings = {
        scrollback-limit = 10000;
        #NOTE(ghostty): not using ghostty for splits or tabs so nearly all default binds conflict Hypr, nvim, or zellij

        confirm-close-surface = false;
        background-opacity = 0.8;
        window-padding-x = 4;
        clipboard-read = "allow";
        clipboard-write = "allow";
        clipboard-paste = "allow";
        copy-on-select = "clipboard";

        # background = "black";
        # window-padding-color = "background";
        # font-family = "0xProto";
        # font-size = 10;
        # mouse-hide-while-typing = true;
        # auto-update = "off";
        # gtk-titlebar = false;
        # shell-integration = "none";
        # linux-cgroup = "always";
        # resize-overlay = "never";

        keybind = [
          "ctrl+shift+d=inspector:toggle"
          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+v=paste_from_clipboard"
          # Fix fixterm conflict with zsh ^[ character https://github.com/ghostty-org/ghostty/discussions/5071
          "ctrl+left_bracket=text:\\x1b"
          "ctrl+shift+minus=decrease_font_size:1"
          "ctrl+shift+plus=increase_font_size:1"
          "ctrl+shift+0=reset_font_size"
          #
          # ========== UNBIND ==========
          #
          "ctrl+shift+e=unbind" # new_split
          "ctrl+shift+n=unbind" # new_window
          "ctrl+shift+t=unbind" # new_tab
        ];
      };
    };
  };
}
