{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gh
    git-lfs
    git-quick-stats
    gitleaks
    gitlint
    bfg-repo-cleaner
    ugit
    git-who
  ];
}
