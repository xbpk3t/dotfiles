{mylib, ...}: {
  imports = mylib.scanPaths ./.;

  environment.shells = with pkgs; [
    # https://mynixos.com/nixpkgs/package/psmisc
    # https://gitlab.com/psmisc/psmisc
    # Install it for fuser
    psmisc
  ];
}
