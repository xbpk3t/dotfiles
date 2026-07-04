{ pkgs, ... }:
{
  # Terraform LSP 包，供 zed/helix 等 IDE 使用
  modules.langs.lsp.packages = with pkgs; [
    terraform-ls
  ];

  home.packages = with pkgs; [
    # CICD
    # ansible  # Temporarily disabled due to hash mismatch in ncclient dependency

    opentofu

    terramate

    # [2026-03-27] conflict with terramate
    # > `/nix/store/irwfbfmq4696wvf3h3w6pnjsf77hw8ds-tenv-4.9.3/bin/terramate' and
    # > `/nix/store/prgxvl5sw4sn44i9sinv82asj1fihhcc-terramate-0.16.0/bin/terramate'
    # tenv

    terranix

    # ==================== 新增：带 Cloudflare provider 的 OpenTofu ====================
    #    (opentofu.withPlugins (p: [
    #      p.cloudflare_cloudflare # terraform-providers.cloudflare 已重命名为 cloudflare_cloudflare

    #      # 如果以后还想加其他 provider，就继续往这里加，例如：
    #      # p.aws
    #      # p.null
    #      # p.random
    #    ]))

    # === Terraform 代码质量 ===
    tflint
    terraform-docs
  ];
}
