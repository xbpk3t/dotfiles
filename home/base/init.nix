{
  pkgs,
  lib,
  userMeta,
  ...
}: let
  username = userMeta.username;
in {
  home = {
    inherit username;
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then "/Users/${username}"
      else "/home/${username}"
    );
    stateVersion = lib.mkDefault "24.11";
  };

  programs.home-manager.enable = true;
}
