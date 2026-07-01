{
  mylib,
  pkgs,
  ...
}:
{
  imports = mylib.scanPaths ./.;

  environment.systemPackages = with pkgs; [
    psmisc
    systemd-manager-tui
  ];
}
