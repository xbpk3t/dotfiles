# terranix: Cloudflare Email Routing rules for lucc.dev.
#
# 生成：
#   task tf:terranix
# 回退：git revert 会恢复同目录被删除的 HCL 文件。
#
# 范围与 HCL 版本保持一致：只管理定向转发规则。
# catch-all（live = disabled + drop）有意不由 Terraform 管理，原因见下方注释。
_:
let
  facts = import ../../../../../facts.nix;
  infraLib = import ../../../../../terranix-lib.nix;

  zoneId = facts.cloudflare.zone_id;
in
{
  terraform = infraLib.mkTerraform {
    stateKey = "homelab/cloudflare/lucc.dev/email-routing/terraform.tfstate";
    r2Endpoint = facts.cloudflare.r2_endpoint;
    providers.cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5.0";
    };
  };

  provider.cloudflare = { };

  # me@lucc.dev -> Gmail；对应规则保持启用。
  resource.cloudflare_email_routing_rule.forward_me = {
    zone_id = zoneId;
    name = "Rule created at 2025-02-20T06:52:34.085Z";
    enabled = true;
    priority = 0;

    matchers = [
      {
        type = "literal";
        field = "to";
        value = "me@lucc.dev";
      }
    ];

    actions = [
      {
        type = "forward";
        value = [ "jeffcottlu@gmail.com" ];
      }
    ];
  };

  import = [
    {
      to = "cloudflare_email_routing_rule.forward_me";
      id = "1c07a1b84d8273f4dfa6c3adce513f94/ed10843353a6484e8b0036a67928b634";
    }
  ];

  # 注意：catch-all（当前 live = disabled + drop）有意不由 Terraform 管理。
  #
  # Why: provider v5 的 cloudflare_email_routing_catch_all.tag 是 computed-only，
  # 每次 plan 都会出现 "tag -> (known after apply)" 的永久 diff，导致 GitOps
  # drift 永远报红（v5.18.0 与 v5.29.0 都复现）。
  #
  # live 配置已固定为 disabled + drop；需要修改时走 Dashboard 或 API。如果
  # provider 后续修复，可以重新加回 resource + import。
}
