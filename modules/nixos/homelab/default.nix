{
  mylib,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  environment.systemPackages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/psmisc
    # https://gitlab.com/psmisc/psmisc
    # Install it for fuser
    psmisc
  ];
}
