{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.devops.tf;
in
{
  options.modules.devops.tf = {
    enable = lib.mkEnableOption "Terraform/OpenTofu toolchain";

    opentofu.enable = lib.mkEnableOption "OpenTofu + terranix";

    terramate.enable = lib.mkEnableOption "Terramate";

    lint.enable = lib.mkEnableOption "Terraform lint/docs (tflint / terraform-docs)";

    ansible.enable = lib.mkEnableOption "Ansible / ansible-lint";
  };

  config = lib.mkMerge [
    {
      # 注意：保持无条件 definition（空列表也算），否则选项 default 会重新生效。
      # Terraform LSP 包，供 zed/helix 等 IDE 使用
      modules.langs.lsp.packages = lib.optionals cfg.enable [ pkgs.terraform-ls ];
    }
    (lib.mkIf cfg.enable {
      home.packages =
        with pkgs;
        lib.optionals cfg.opentofu.enable [
          opentofu

          # ==================== 新增：带 Cloudflare provider 的 OpenTofu ====================
          #    (opentofu.withPlugins (p: [
          #      p.cloudflare_cloudflare # terraform-providers.cloudflare 已重命名为 cloudflare_cloudflare

          #      # 如果以后还想加其他 provider，就继续往这里加，例如：
          #      # p.aws
          #      # p.null
          #      # p.random
          #    ]))

          terranix
        ]
        ++ lib.optionals cfg.terramate.enable [
          terramate

          # [2026-03-27] conflict with terramate
          # > `/nix/store/irwfbfmq4696wvf3h3w6pnjsf77hw8ds-tenv-4.9.3/bin/terramate' and
          # > `/nix/store/prgxvl5sw4sn44i9sinv82asj1fihhcc-terramate-0.16.0/bin/terramate'
          # tenv
        ]
        ++ lib.optionals cfg.lint.enable [
          # === Terraform 代码质量 ===
          tflint
          terraform-docs
        ]
        ++ lib.optionals cfg.ansible.enable [
          # CICD
          ansible
          ansible-lint
        ];
    })
  ];
}
