{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # fluxcd
    # argocd

    # ko # build go project to container image
    # pkgs-stable.kubernetes-helm
    # argocd

    #
    # For flux cli
    fluxcd

    fluxcd-operator
  ];
}
