{ flake, myvars, ... }:
let
  inherit (flake) inputs;
  self = inputs.self;
  mylib = import (self + /lib) { inherit (inputs.nixpkgs) lib; };
  myvars = import (self + /vars) { inherit (inputs.nixpkgs) lib; };
in {
  imports = [
    (self + /modules/home/base)
    (self + /modules/home/darwin)
  ];

  home = {
    username = myvars.username;
    homeDirectory = "/Users/${myvars.username}";
  };

  programs.home-manager.enable = true;

  modules = {
    ssh = {
      enable = true;
      hosts = {
        github.enable = true;
        vps.enable = true;
      };
    };
  };
}
