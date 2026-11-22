# terranix: Cloudflare Workers custom domains for lucc.dev.
#
# 生成：
#   task tf:terranix
# 回退：git revert 会恢复同目录被删除的 HCL 文件。
#
# Worker 脚本由各自的部署链路负责，infra 只负责域名/DNS ownership。
#
# docs.lucc.dev / blog.lucc.dev 由 docs repo 的 Wrangler routes 管理，
# 刻意不纳入这里，避免 Terraform 和 Wrangler 双写。
{ lib, ... }:
let
  facts = import ../../../../../facts.nix;
  infraLib = import ../../../../../terranix-lib.nix;

  # 这些 custom domain 目前是 dashboard/外部部署留下的，纳入 Terraform 收编。
  # 地址与旧资源 music 分开，避免改变 music 的 state 地址。
  additionalDomains = {
    dp-lucc = {
      id = "ea312fb627610bd6e294bb3a5b23d36a0130f88a";
      hostname = "dp.lucc.dev";
      service = "dp";
      zone_id = facts.cloudflare.zone_id;
    };

    dp-hxha = {
      id = "04785ab2f5878c4f523ac7a1136ee6bf90d554b2";
      hostname = "dp.hxha.xyz";
      service = "dp";
      zone_id = "7fc45c38cd3076f415f74ee899fc91e6";
    };

    dp-lucas1 = {
      id = "83422ae3774d473f741fa6c6ef3fe4c2ecbb7b25";
      hostname = "dp.lucas1.xyz";
      service = "dp";
      zone_id = "2de11ed56efd0b7d6aee9c0d090de3e2";
    };

    temp-email-api = {
      id = "4114869823805ccc549dfd01bce3f6a33d34bcb5";
      hostname = "temp-email-api.lucc.dev";
      service = "cloudflare_temp_email";
      zone_id = facts.cloudflare.zone_id;
    };

    temp-mail = {
      id = "dd9c471c95d19465509ec6902ba41801a04e0993";
      hostname = "temp-mail.lucc.dev";
      service = "cloudflare_temp_email";
      zone_id = facts.cloudflare.zone_id;
    };
  };
in
{
  terraform = infraLib.mkTerraform {
    stateKey = "homelab/cloudflare/lucc.dev/workers/terraform.tfstate";
    r2Endpoint = facts.cloudflare.r2_endpoint;
    providers.cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5.0";
    };
  };

  provider.cloudflare = { };

  # custom domain 由 Cloudflare 自动创建/接管 DNS 记录和证书。
  resource.cloudflare_workers_custom_domain.music = {
    account_id = facts.cloudflare.account_id;
    zone_id = facts.cloudflare.zone_id;
    hostname = "music.lucc.dev";
    service = "music";
  };

  resource.cloudflare_workers_custom_domain.domains = {
    for_each = additionalDomains;

    account_id = facts.cloudflare.account_id;
    zone_id = lib.tf.ref "each.value.zone_id";
    hostname = lib.tf.ref "each.value.hostname";
    service = lib.tf.ref "each.value.service";
  };

  import = map (key: {
    to = "cloudflare_workers_custom_domain.domains[\"${key}\"]";
    id = "${facts.cloudflare.account_id}/${additionalDomains.${key}.id}";
  }) (builtins.attrNames additionalDomains);
}
