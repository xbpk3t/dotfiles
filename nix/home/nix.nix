{pkgs, ...}: {
  home.packages = with pkgs; [
    deadnix # https://github.com/astro/deadnix
    statix # https://github.com/oppiliappan/statix
    alejandra # https://github.com/kamadorueda/alejandra

    age # https://github.com/FiloSottile/age 用来处理 agenix
    sops
  ];

  programs.nix-index = {
    enable = true;
  };
}
