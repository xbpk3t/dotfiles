# terranix: Cloudflare Workers custom domains for lucc.dev.
#
# 生成：
#   task tf:terranix
# 回退：git revert 会恢复同目录被删除的 HCL 文件。
#
# Worker 脚本由 zzz repo 的 CI 部署，infra 只负责域名/DNS ownership。
_:
let
  facts = import ../../../../../facts.nix;
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
      key = "homelab/cloudflare/lucc.dev/workers/terraform.tfstate";
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

  # custom domain 由 Cloudflare 自动创建/接管 DNS 记录和证书。
  resource.cloudflare_workers_custom_domain.music = {
    account_id = facts.cloudflare.account_id;
    zone_id = facts.cloudflare.zone_id;
    hostname = "music.lucc.dev";
    service = "music";
  };
}
