{ pkgs, ... }:
{
  home.packages = with pkgs; [

    actionlint
    
    # fluxcd
    # argocd

    # ko # build go project to container image
    # pkgs-stable.kubernetes-helm
    # argocd

    #
    # For flux cli
    fluxcd

    fluxcd-operator

    # === Release 自动化 ===
    # tags(desc): 发布交付 > Release自动化 > CI/CD
    goreleaser
  ];
}
