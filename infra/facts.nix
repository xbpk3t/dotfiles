# 跨 Nix / Terraform 共享的 infra facts。
#
# 设计原则：
# - 能从 hosts/*/meta.nix 派生的事实，不在 Terraform locals 里重复写。
# - 只放 NixOS 与云资源都需要的事实；纯 Terraform provider 细节不要进来。
# - terranix stack 直接 import 本文件；不再生成中间 JSON。
let
  # facts 只消费 nixos-vps-dev 的公网 IP（api/as/rsshub 共用）。
  # 其他 host 的 DERP 事实由 lib/fleet 负责，不在这里重复。
  dev = import ../hosts/nixos-vps/dev/meta.nix;

  account_id = "96540bd100b82adba941163704660c31";
  zone_name = "lucc.dev";
  dev_ip = dev.publicIpv4;

  aRecord = name: content: proxied: comment: {
    id = null;
    inherit
      name
      content
      proxied
      comment
      ;
    type = "A";
    ttl = 1;
    priority = null;
  };
in
{
  cloudflare = {
    inherit account_id;
    zone_id = "1c07a1b84d8273f4dfa6c3adce513f94";
    inherit zone_name;
    r2_endpoint = "https://${account_id}.r2.cloudflarestorage.com";

    d1 = {
      docs = {
        id = "96375ee2-188f-44d4-ab16-eaa06828a4ac";
        name = "docs";
      };
      vscs = {
        id = "6f4f878f-4845-4801-9386-458c612f0a72";
        name = "vscs";
      };
    };

    r2.buckets = {
      docs = "docs";
      docs-wiki = "docs-wiki";
    };

    kv.namespaces = {
      # docs-session 由 docs 相关 Worker 使用；__me-workers_sites_assets 是
      # Workers Sites 自动创建的 assets namespace，刻意不纳管。
      docs-session = {
        id = "bb27afbe4c4b4083a126def401be39e3";
        title = "docs-session";
      };
    };
  };

  tailscale = {
    tailnet = "xbpk3t.github";
  };

  dns = {
    # 这些记录的内容来自 hosts/*/meta.nix；手写记录（MX/DKIM/apex 占位等）
    # 留在 dns/terranix.nix 的 manualRecords 里。
    shared_records = {
      api = aRecord "api.${zone_name}" dev_ip true "AxonHub";
      as = aRecord "as.${zone_name}" dev_ip true "OpenList (ASMR)";
      rsshub = (aRecord "rsshub.${zone_name}" dev_ip true "rsshub") // {
        id = "1eb043e1ffe747891513e47be11b0a6f";
      };
    };
  };
}
