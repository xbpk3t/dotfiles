{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      # 分类：Helm 工具链
      # https://github.com/komodorio/helm-dashboard/
      helm-dashboard
      # https://github.com/mkubaczyk/helmsman

      # Kubernetes 相关工具
      kubernetes-helm
      helmfile

      # https://github.com/nix-community/nixhelm
      #
      #
      # https://nixos.wiki/wiki/Helm_and_Helmfile
      #
      #
      # https://github.com/redpanda-data/helm-charts

      # pkgs-stable.kubernetes-helm
    ]
    ++ (with pkgs.kubernetes-helmPlugins; [
      # https://mynixos.com/packages/kubernetes-helmPlugins

      # helm plugin install https://github.com/databus23/helm-diff
      helm-diff
    ]);
}
