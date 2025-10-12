{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # GUI apps
    # e-book viewer(.epub/.mobi/...)
    # do not support .pdf
    # foliate

    # reqable

    # Media
    # vlc

    # File managers
    # FIXME 暂时禁用
    # xfce.thunar

    # 只有linux
    # pavucontrol

    # Image viewers
    # feh
    # imv

    # remote desktop(rdp connect)
    # FIXME [2025-10-12] rustdesk目前有bug，会报错 Wayland requires higher version of linux distro. Please try X11 desktop or change your OS. 等待fix，fix之后再使用
    # https://github.com/rustdesk/rustdesk/discussions/12897
    # rustdesk

    # remmina
    # freerdp # required by remmina
    # my custom hardened packages
  ];

  # FIXME 配置 rustdesk-server
  # https://mynixos.com/nixpkgs/options/services.rustdesk-server
}
