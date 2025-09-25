{pkgs, ...}: {
  home.packages = with pkgs; [
    deadnix # https://github.com/astro/deadnix
    statix # https://github.com/oppiliappan/statix
    alejandra # https://github.com/kamadorueda/alejandra
  ];

  programs.nix-index = {
    enable = true;
  };
}
