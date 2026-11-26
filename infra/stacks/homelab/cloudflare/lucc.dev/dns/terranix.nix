# terranix 试点：把 cloudflare/lucc.dev/dns 这个 stack 从 HCL 迁到 Nix。
#
# 生成：
#   task tf:terranix
# 等价命令（仓库根目录）：
#   nix develop .#infra --command bash -c \
#     'terranix --with-nulls infra/stacks/homelab/cloudflare/lucc.dev/dns/terranix.nix \
#        | jq -S . > infra/stacks/homelab/cloudflare/lucc.dev/dns/generated.tf.json'
#
# 回退：本 commit 删除了同目录的 main.tf / locals.tf / imports.tf /
# versions.tf / provider.tf，`git revert` 即可恢复。
{ lib, ... }:
let
  facts = import ../../../../../facts.nix;
  infraLib = import ../../../../../terranix-lib.nix;

  # 所有 DNS record 共用的字段形状；记录本身只写各自不同的字段。
  mkRecord =
    {
      id ? null,
      name,
      type,
      content,
      ttl ? 1,
      proxied ? true,
      comment ? null,
      priority ? null,
    }:
    {
      inherit
        id
        name
        type
        content
        ttl
        proxied
        comment
        priority
        ;
    };

  # DERP A 记录直接从 lib/fleet 派生，和 Tailscale stack 同源；
  # 不再维护 fleet.generated.json。
  fleet = import ../../../../../../lib/fleet { inherit lib; };
  derpRecords = lib.mapAttrs' (
    _name: node:
    lib.nameValuePair node.derper.dnsKey (mkRecord {
      name = node.derper.domain;
      type = "A";
      content = node.publicIpv4;
      proxied = false;
      comment =
        if node.derper.dnsComment != null then node.derper.dnsComment else "Tailscale DERP (${_name})";
    })
  ) fleet.derperNodes;

  # 这些记录含外部服务 / apex 占位 / Email Routing 的 provider 细节，
  # 暂不进入共享 facts；在 terranix stack 里就地维护。
  manualRecords = {
    blog = mkRecord {
      id = "db66877fcacde96aa9844c8a91ec3a16";
      name = "blog.lucc.dev";
      type = "AAAA";
      content = "100::";
    };
    cdn = mkRecord {
      id = "68bf0f40f96ff96acbd75a119e988750";
      name = "cdn.lucc.dev";
      type = "CNAME";
      content = "public.r2.dev";
    };
    docs = mkRecord {
      id = "056c4cc7e02dfac9d69c9ff02d522314";
      name = "docs.lucc.dev";
      type = "AAAA";
      content = "100::";
    };
    # apex 由 Worker route `lucc.dev/* -> me` 拦截；这里用一个不指向任何源的
    # proxied AAAA 占位，避免继续引用已删除的 Pages 项目。
    # 若移除该 route，需要同步改这条记录。
    root = mkRecord {
      id = "01663f7a1946bf5b32ab169b39fc2940";
      name = "lucc.dev";
      type = "AAAA";
      content = "100::";
      comment = "Worker route lucc.dev/* -> me (apex placeholder)";
    };
    mx_route3 = mkRecord {
      id = "3bfffe44f3323a9fdbbb8b455622f113";
      name = "lucc.dev";
      type = "MX";
      content = "route3.mx.cloudflare.net";
      proxied = false;
      priority = 51;
    };
    mx_route2 = mkRecord {
      id = "3cbcaf3176b7ea868a57dd13f47512c7";
      name = "lucc.dev";
      type = "MX";
      content = "route2.mx.cloudflare.net";
      proxied = false;
      priority = 38;
    };
    mx_route1 = mkRecord {
      id = "e16cff5af9f8ec1e705fff3020a654f5";
      name = "lucc.dev";
      type = "MX";
      content = "route1.mx.cloudflare.net";
      proxied = false;
      priority = 67;
    };
    dkim = mkRecord {
      id = "650591690a857966f1ca8242f4108ab3";
      name = "cf2024-1._domainkey.lucc.dev";
      type = "TXT";
      content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\"";
      proxied = false;
    };
    spf = mkRecord {
      id = "8eadaa51a16abe012878207f99ae5d33";
      name = "lucc.dev";
      type = "TXT";
      content = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\"";
      proxied = false;
    };
    dp = mkRecord {
      id = "6bc3b7e5f9391562ac7df710c3578362";
      name = "dp.lucc.dev";
      type = "AAAA";
      content = "100::";
    };
  };

  # Tailscale-only 服务别名：DNS A 直接指向 relay 的 tailnet IP（DNS-only），
  # 公网无法路由到 100.64/10；客户端在 tailnet 内解析后走 kernel-TCP relay。
  relayRecords = {
    llm = mkRecord {
      name = "llm.${facts.cloudflare.zone_name}";
      type = "A";
      content = fleet.nodes."nixos-vps-agt".tailscale.ip;
      proxied = false;
      comment = "LLM gateway (tailnet relay, kernel TCP)";
    };
  };

  records = facts.dns.shared_records // derpRecords // manualRecords // relayRecords;
  importable = lib.filterAttrs (_: record: record.id != null) records;

  # derp key 与手写记录撞名时 `//` 会静默覆盖其中一条，Terraform 随后会删除/
  # 覆盖 live record。生成期直接报错，别让生成物悄悄丢记录。
  derpKeyCollisions = lib.intersectLists (builtins.attrNames derpRecords) (
    builtins.attrNames (facts.dns.shared_records // manualRecords)
  );
in
assert lib.assertMsg (derpKeyCollisions == [ ])
  "dns terranix: derp dnsKey collides with manual records: ${lib.concatStringsSep ", " derpKeyCollisions}";
{
  terraform = infraLib.mkTerraform {
    stateKey = "homelab/cloudflare/lucc.dev/dns/terraform.tfstate";
    r2Endpoint = facts.cloudflare.r2_endpoint;
    providers.cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5.0";
    };
  };

  # provider token 仍由 CLOUDFLARE_API_TOKEN 注入；这里只需要空 provider 配置。
  provider.cloudflare = { };

  resource.cloudflare_dns_record.records = {
    for_each = records;

    zone_id = facts.cloudflare.zone_id;
    name = lib.tf.ref "each.value.name";
    ttl = lib.tf.ref "each.value.ttl";
    type = lib.tf.ref "each.value.type";
    content = lib.tf.ref "each.value.content";
    proxied = lib.tf.ref "each.value.proxied";
    comment = lib.tf.ref "each.value.comment";
    priority = lib.tf.ref "each.value.priority";
  };

  # 仍然只 import 已经有 live id 的记录；地址与 HCL 版本保持一致。
  import = map (key: {
    to = "cloudflare_dns_record.records[\"${key}\"]";
    id = "${facts.cloudflare.zone_id}/${importable.${key}.id}";
  }) (builtins.attrNames importable);

  # 旧地址 -> for_each 地址的平滑迁移；只保留仍由本 stack 管理的 record。
  moved = [
    {
      from = "cloudflare_dns_record.rsshub_lucc_dev_a_09";
      to = "cloudflare_dns_record.records[\"rsshub\"]";
    }
    {
      from = "cloudflare_dns_record.blog_lucc_dev_cname_12";
      to = "cloudflare_dns_record.records[\"blog\"]";
    }
    {
      from = "cloudflare_dns_record.cdn_lucc_dev_cname_13";
      to = "cloudflare_dns_record.records[\"cdn\"]";
    }
    {
      from = "cloudflare_dns_record.docs_lucc_dev_cname_14";
      to = "cloudflare_dns_record.records[\"docs\"]";
    }
    {
      from = "cloudflare_dns_record.lucc_dev_cname_16";
      to = "cloudflare_dns_record.records[\"root\"]";
    }
    {
      from = "cloudflare_dns_record.lucc_dev_mx_19";
      to = "cloudflare_dns_record.records[\"mx_route3\"]";
    }
    {
      from = "cloudflare_dns_record.lucc_dev_mx_20";
      to = "cloudflare_dns_record.records[\"mx_route2\"]";
    }
    {
      from = "cloudflare_dns_record.lucc_dev_mx_21";
      to = "cloudflare_dns_record.records[\"mx_route1\"]";
    }
    {
      from = "cloudflare_dns_record.cf2024_1_domainkey_lucc_dev_txt_22";
      to = "cloudflare_dns_record.records[\"dkim\"]";
    }
    {
      from = "cloudflare_dns_record.lucc_dev_txt_23";
      to = "cloudflare_dns_record.records[\"spf\"]";
    }
    {
      from = "cloudflare_dns_record.dp_lucc_dev_aaaa_24";
      to = "cloudflare_dns_record.records[\"dp\"]";
    }
  ];
}
