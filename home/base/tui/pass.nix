{
  config,
  lib,
  myvars,
  pkgs,
  mylib,
  ...
}: let
  passStorePath = "${myvars.projectRoot}/pass-store";
  passHelpers = mylib.pass.mkPassHelpers {
    inherit pkgs;
    homeDir = config.home.homeDirectory;
    scriptName = "pass-env";
  };
in {
  # https://mynixos.com/home-manager/options/programs.password-store
  programs.password-store = {
    enable = true;
    package = pkgs.pass;
    settings = {
      PASSWORD_STORE_DIR = lib.mkDefault "${config.home.homeDirectory}/.password-store";
      PASSWORD_STORE_GPG_OPTS = "--quiet";
    };
  };

  home.sessionVariables = {
    PASSWORD_STORE_DIR = lib.mkDefault "${config.home.homeDirectory}/.password-store";
    PASSWORD_STORE_GPG_OPTS = lib.mkDefault "--quiet";
  };

  # https://mynixos.com/nixpkgs/packages/passExtensions
  home.packages = [
    passHelpers.script
    pkgs.passExtensions.pass-otp
    pkgs.passExtensions.pass-update
  ];

  home.file.".password-store" = {
    source = config.lib.file.mkOutOfStoreSymlink passStorePath;
    recursive = true;
  };
}
