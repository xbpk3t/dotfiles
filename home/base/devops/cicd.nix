{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.devops.cicd;
in
{
  options.modules.devops.cicd.enable =
    lib.mkEnableOption "CI/CD tools (fluxcd / goreleaser / actionlint)";

  config.home.packages = lib.optionals cfg.enable (
    with pkgs;
    [

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
    ]
  );
}
