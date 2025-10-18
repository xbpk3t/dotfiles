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

    # 只有linux
    # pavucontrol

    # Image viewers
    # feh
    # imv
  ];
}
