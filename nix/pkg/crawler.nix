{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    katana
  ];
}
