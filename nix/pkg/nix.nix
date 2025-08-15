{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # TODO 1、用这几个工具跑一下现有的nix配置文件。2、做到Taskfile.nix.yml以及pre-commit里面
    deadnix # https://github.com/astro/deadnix
    nixpkgs-hammering # https://github.com/jtojnar/nixpkgs-hammering
    statix # https://github.com/oppiliappan/statix
    nixpkgs-lint-community # https://github.com/nix-community/nixpkgs-lint
  ];
}
