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
  infraLib = import ../../../../../terranix-lib.nix;
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
}
