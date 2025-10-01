{pkgs, ...}: {
  home.packages = with pkgs; [
    deadnix # https://github.com/astro/deadnix
    statix # https://github.com/oppiliappan/statix
    alejandra # https://github.com/kamadorueda/alejandra

    # nix related
    #
    # it provides the command `nom` works just like `nix
    # with more details log output
    nix-output-monitor
    hydra-check # check hydra(nix's build farm) for the build status of a package
    nix-index # A small utility to index nix store paths
    nix-init # generate nix derivation from url
    # https://github.com/nix-community/nix-melt
    nix-melt # A TUI flake.lock viewer
    # https://github.com/utdemir/nix-tree
    nix-tree # A TUI to visualize the dependency graph of a nix derivation

    colmena # NixOS 远程部署工具
  ];

  programs.nix-index = {
    enable = true;
  };
}
