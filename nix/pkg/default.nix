{ pkgs, ... }:

{
  imports = [
    ./network.nix
    ./db.nix
    ./langs.nix
    ./ts.nix
    ./golang.nix
    ./devops.nix
    ./git.nix
    ./test.nix
    ./k8s.nix
    ./crawler.nix
    ./docker.nix
    ./nix.nix
  ];
}
