{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      # 分类：Helm 工具链
      helm-dashboard
      kubernetes-helm
      helmfile
    ]
    ++ (with pkgs.kubernetes-helmPlugins; [

      helm-diff
    ]);
}
