# terranix: Cloudflare D1 databases (adopt existing databases).
#
# 生成：
#   task tf:terranix
# 回退：git revert 会恢复同目录被删除的 HCL 文件。
#
# 资源地址保持与 HCL 版本一致：
#   cloudflare_d1_database.databases["docs"|"vscs"]
{ lib, ... }:
let
  facts = import ../../../../../facts.nix;
  infraLib = import ../../../../../terranix-lib.nix;

  accountId = facts.cloudflare.account_id;

  # D1 是 account-scope 资源，不属于某一个 zone。
  databases = {
    docs = {
      uuid = facts.cloudflare.d1.docs.id;
      name = facts.cloudflare.d1.docs.name;
      jurisdiction = null;
      primary_location_hint = null;
      read_replication_mode = "disabled";
    };

    # https://github.com/xbpk3t/zzz
    vscs = {
      uuid = facts.cloudflare.d1.vscs.id;
      name = facts.cloudflare.d1.vscs.name;
      jurisdiction = null;
      primary_location_hint = null;
      read_replication_mode = "disabled";
    };
  };
in
{
  terraform = infraLib.mkTerraform {
    stateKey = "homelab/cloudflare/account/d1/terraform.tfstate";
    r2Endpoint = facts.cloudflare.r2_endpoint;
    providers.cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5.0";
    };
  };

  provider.cloudflare = { };

  resource.cloudflare_d1_database.databases = {
    for_each = databases;

    account_id = accountId;
    name = lib.tf.ref "each.value.name";
    jurisdiction = lib.tf.ref "each.value.jurisdiction";
    primary_location_hint = lib.tf.ref "each.value.primary_location_hint";

    read_replication = {
      mode = lib.tf.ref "each.value.read_replication_mode";
    };
  };

  # 仍然只 import 已经存在的数据库；地址与 HCL 版本保持一致。
  import = map (key: {
    to = "cloudflare_d1_database.databases[\"${key}\"]";
    id = "${accountId}/${databases.${key}.uuid}";
  }) (builtins.attrNames databases);
}
