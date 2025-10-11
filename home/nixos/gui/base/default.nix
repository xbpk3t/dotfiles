{mylib, pkgs, ...}: {
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

    # remmina
    # freerdp # required by remmina
    # my custom hardened packages
  ];


  # FIXME 配置 rustdesk-server
  # https://mynixos.com/nixpkgs/options/services.rustdesk-server

}
