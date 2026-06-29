{ pkgs, ... }:
{
  home.packages = with pkgs; [
    fdroidcl
    android-tools
    scrcpy
  ];
}
