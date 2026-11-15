{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.ms.helm;
in
{
  options.modules.ms.helm.enable =
    lib.mkEnableOption "Helm toolchain (helm / helmfile / helm-dashboard / helm-ls)";

  config = lib.mkMerge [
    {
      # 注意：保持无条件 definition（空列表也算），否则选项 default 会重新生效。
      # Helm LSP 包，供 zed/helix 等 IDE 使用
      modules.langs.lsp.packages = lib.optionals cfg.enable [ pkgs.helm-ls ];
    }
    (lib.mkIf cfg.enable {
      home.packages =
        with pkgs;
        [
          # 分类：Helm 工具链
          helm-dashboard
          kubernetes-helm
          helmfile
        ]
        ++ (with kubernetes-helmPlugins; [
          helm-diff
        ]);
    })
  ];
}
