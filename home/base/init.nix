{
  myvars,
  pkgs,
  lib,
  ...
}: {
  home = {
    username = myvars.username;
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then "/Users/${myvars.username}"
      else "/home/${myvars.username}"
    );
    stateVersion = lib.mkDefault "24.11";
  };

  programs.home-manager.enable = true;
}
