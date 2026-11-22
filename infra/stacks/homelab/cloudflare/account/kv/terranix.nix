# terranix: Cloudflare Workers KV namespaces (adopt docs-session).
#
# 生成：
#   task tf:terranix
# 回退：git revert 会恢复整份 stack。
#
# 只纳管 docs-session。`__me-workers_sites_assets` 是 Workers Sites 自动创建的
# assets namespace，仍有数据，刻意保持非 Terraform 管理，避免和部署链路双写。
{ lib, ... }:
let
  facts = import ../../../../../facts.nix;
  infraLib = import ../../../../../terranix-lib.nix;

  accountId = facts.cloudflare.account_id;
  namespaces = facts.cloudflare.kv.namespaces;
in
{
  terraform = infraLib.mkTerraform {
    stateKey = "homelab/cloudflare/account/kv/terraform.tfstate";
    r2Endpoint = facts.cloudflare.r2_endpoint;
    providers.cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5.0";
    };
  };

  provider.cloudflare = { };

  resource.cloudflare_workers_kv_namespace.namespaces = {
    for_each = namespaces;

    account_id = accountId;
    title = lib.tf.ref "each.value.title";
  };

  # 只 import 已经存在的 namespace；地址与旧 HCL stack 保持一致。
  import = map (key: {
    to = "cloudflare_workers_kv_namespace.namespaces[\"${key}\"]";
    id = "${accountId}/${namespaces.${key}.id}";
  }) (builtins.attrNames namespaces);
}
