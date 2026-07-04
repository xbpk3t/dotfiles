{ pkgs, ... }:
{
  # Helm LSP 包，供 zed/helix 等 IDE 使用
  modules.langs.lsp.packages = with pkgs; [
    helm-ls
  ];

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
