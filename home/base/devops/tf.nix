{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # CICD
    # ansible  # Temporarily disabled due to hash mismatch in ncclient dependency

    opentofu

    # https://github.com/cloudflare/cf-terraforming/
    # [2026-03-27] 注释了，目前已经用不到这个pkg了。
    # cf-terraforming

    # 注意 tf框架 选择使用 terramate 而非 terragrunt
    # https://github.com/terramate-io/terramate
    terramate

    # [2026-03-27] conflict with terramate
    # > `/nix/store/irwfbfmq4696wvf3h3w6pnjsf77hw8ds-tenv-4.9.3/bin/terramate' and
    # > `/nix/store/prgxvl5sw4sn44i9sinv82asj1fihhcc-terramate-0.16.0/bin/terramate'
    # tenv

    # ==================== 新增：带 Cloudflare provider 的 OpenTofu ====================
    #    (opentofu.withPlugins (p: [
    #      p.cloudflare_cloudflare # terraform-providers.cloudflare 已重命名为 cloudflare_cloudflare

    #      # 如果以后还想加其他 provider，就继续往这里加，例如：
    #      # p.aws
    #      # p.null
    #      # p.random
    #    ]))
  ];
}
