{pkgs, ...}: {
  # XDG Portal 配置
  # 基于 hyprland 的 xdg.nix 配置进行调整
  xdg.portal = {
    enable = true;

    config = {
      common = {
        # 使用 xdg-desktop-portal-gtk 和 niri 的 portal
        default = [
          "gtk"
          "gnome"
        ];
        # gnome-keyring 处理密钥门户
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };

      # niri 特定配置
      niri = {
        default = [
          "gtk"
          "gnome"
        ];
        "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
      };
    };

    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };
}
