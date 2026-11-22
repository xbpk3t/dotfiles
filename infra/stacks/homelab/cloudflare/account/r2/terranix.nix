# terranix: Cloudflare R2 buckets (adopt existing buckets).
#
# 生成：
#   task tf:terranix
# 回退：git revert 会恢复同目录被删除的 HCL 文件。
#
# 资源地址保持与 HCL 版本一致：
#   cloudflare_r2_bucket.buckets["docs"|"docs-wiki"]
{ lib, ... }:
let
  facts = import ../../../../../facts.nix;
  infraLib = import ../../../../../terranix-lib.nix;

  accountId = facts.cloudflare.account_id;

  # backend 使用的 `luck-dotfiles-opentofu-state` bucket 故意不放进这里：
  # 它必须先于当前 stack 存在，否则会形成 bootstrap 循环依赖。
  buckets = facts.cloudflare.r2.buckets;
in
{
  terraform = infraLib.mkTerraform {
    stateKey = "homelab/cloudflare/account/r2/terraform.tfstate";
    r2Endpoint = facts.cloudflare.r2_endpoint;
    providers.cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5.0";
    };
  };

  provider.cloudflare = { };

  resource.cloudflare_r2_bucket.buckets = {
    for_each = buckets;

    account_id = accountId;
    name = lib.tf.ref "each.value";
  };

  # import 跟随当前 bucket map 自动展开；地址与 HCL 版本保持一致。
  import = map (key: {
    to = "cloudflare_r2_bucket.buckets[\"${key}\"]";
    id = "${accountId}/${buckets.${key}}/default";
  }) (builtins.attrNames buckets);
}
