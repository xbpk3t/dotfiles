{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.gnome;
in {
  options.modules.desktop.gnome = {
    enable = mkEnableOption "GNOME desktop (GDM + gnome-shell, Wayland-first)";
  };

  config = mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        displayManager.gdm = {
          enable = true;
          wayland = true;
        };
        desktopManager.gnome.enable = true;
      };

      # 确保 greetd/其他 DM 不再启用，避免冲突
      greetd.enable = false;
    };

    # GNOME 依赖 dconf
    programs.dconf.enable = true;

    # 基础 GNOME 工具
    environment.systemPackages = with pkgs; [
      gnome-tweaks
      gnomeExtensions.appindicator
    ];
  };
}
