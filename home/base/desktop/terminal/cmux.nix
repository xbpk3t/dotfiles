{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.cmux;
in {
  # ─────────────────────────────────────────────────────────────
  # Behavior matrix: ghostty config deployment triggers
  #
  # cmux (libghostty) reads Ghostty config for terminal rendering.
  # Ghostty config is deployed by ghostty.nix when either ghostty
  # or cmux is enabled (macOS only for cmux).
  #
  #   ghostty.enable  cmux.enable  ghostty config deployed?
  #   ──────────────  ───────────  ─────────────────────────────
  #   false           true         yes (triggered by cmux)
  #   true            false        yes (triggered by ghostty)
  #   false           false        no
  #   true            any          yes (Linux: programs.ghostty)
  #   false           any          no  (Linux: cmux isDarwin=false)
  #
  # Ghostty config is written to XDG path (~/.config/ghostty/config)
  # on macOS, same path as Linux. This path is read by both
  # Ghostty.app and cmux via libghostty.
  # ─────────────────────────────────────────────────────────────

  options.modules.desktop.cmux = {
    enable = mkEnableOption "cmux agent cockpit";
  };

  # cmux 目前仅支持 macOS (Darwin)
  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    # 如果你用 nix-darwin + Homebrew 管 cmux，可以在 nix-darwin 里写：
    #
    # homebrew = {
    #   enable = true;
    #   casks = [ "cmux" ];
    # };
    #
    # 如果你已经用 brew install --cask cmux 装了，这里不需要重复装。

    xdg.configFile."cmux/cmux.json" = {
      force = true;
      text = builtins.readFile ./cmux.jsonc;
    };
  };
}
