{ flake, myvars, ... }:
let
  inherit (flake) inputs;
  self = inputs.self;
  mylib = import (self + /lib) { inherit (inputs.nixpkgs) lib; };
  myvars = import (self + /vars) { inherit (inputs.nixpkgs) lib; };
in {
  imports = [
    (self + /modules/home/base)
    (self + /modules/home/nixos)
  ];

  home = {
    username = myvars.username;
    homeDirectory = "/home/${myvars.username}";
  };

  programs.home-manager.enable = true;

  modules = {
    desktop = {
      nvidia.enable = true;
      gnome.enable = true;
      zed.enable = false;
      kitty.enable = false;
      ghostty.enable = false;
    };
    ssh = {
      enable = true;
      hosts = {
        github.enable = true;
        vps.enable = true;
      };
    };
    tui.nvf.enable = true;
    networking.netbird.enable = true;
  };
}
