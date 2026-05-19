{pkgs, ...}: {
  home.packages = with pkgs; [
    # fluxcd
    # argocd

    # ko # build go project to container image
    # pkgs-stable.kubernetes-helm
    # argocd

    # https://mynixos.com/nixpkgs/package/fluxcd
    #
    # For flux cli
    fluxcd

    # https://mynixos.com/nixpkgs/package/fluxcd-operator
    fluxcd-operator
  ];
}
