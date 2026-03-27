{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.kitty;
in {
  options.modules.desktop.kitty = {
    enable = mkEnableOption "kitty terminal";
  };

  config = mkIf cfg.enable {
    # https://mynixos.com/nixpkgs/package/kitty
    #
    # https://mynixos.com/home-manager/options/programs.kitty
    #
    # https://github.com/kovidgoyal/kitty
    #
    #
    #
    programs.kitty = {
      enable = true;
      package = pkgs.kitty;
      settings = {
        # font_size = 12;
        wheel_scroll_min_lines = 1;
        window_padding_width = 4;
        confirm_os_window_close = 0;
        scrollback_lines = 10000;
        enable_audio_bell = false;
        mouse_hide_wait = 60;
        cursor_trail = 1;
        tab_fade = 1;
        active_tab_font_style = "bold";
        inactive_tab_font_style = "bold";

        font-family = "JetBrains Mono";
        font-size = 13;

        # Tab configuration
        tab_bar_edge = "top";
        tab_bar_margin_width = 0;
        tab_bar_style = "powerline"; # fade

        enabled_layouts = "splits";
      };
      extraConfig = builtins.readFile ./kitty.conf;
    };
  };
}
