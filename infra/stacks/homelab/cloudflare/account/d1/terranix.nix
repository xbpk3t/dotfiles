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
  terraform = {
    required_version = ">= 1.10.0";

    required_providers.cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5.0";
    };

    backend.s3 = {
      bucket = "luck-dotfiles-opentofu-state";
      key = "homelab/cloudflare/account/d1/terraform.tfstate";
      region = "auto";

      endpoints.s3 = facts.cloudflare.r2_endpoint;

      skip_credentials_validation = true;
      skip_metadata_api_check = true;
      skip_region_validation = true;
      skip_requesting_account_id = true;
      skip_s3_checksum = true;
      use_path_style = true;
      use_lockfile = true;
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
