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

  # 这些记录含外部服务 / Pages / Email Routing 的 provider 细节，
  # 暂不进入共享 facts；terranix 试点就地把它们搬成 Nix 数据。
  manualRecords = {
    blog = {
      id = "db66877fcacde96aa9844c8a91ec3a16";
      name = "blog.lucc.dev";
      type = "AAAA";
      content = "100::";
      ttl = 1;
      proxied = true;
      comment = null;
      priority = null;
    };
    cdn = {
      id = "68bf0f40f96ff96acbd75a119e988750";
      name = "cdn.lucc.dev";
      type = "CNAME";
      content = "public.r2.dev";
      ttl = 1;
      proxied = true;
      comment = null;
      priority = null;
    };
    docs = {
      id = "056c4cc7e02dfac9d69c9ff02d522314";
      name = "docs.lucc.dev";
      type = "AAAA";
      content = "100::";
      ttl = 1;
      proxied = true;
      comment = null;
      priority = null;
    };
    root = {
      id = "a80a731e11c54cc0a9707b454b0dea63";
      name = "lucc.dev";
      type = "CNAME";
      content = "me-4b9.pages.dev";
      ttl = 1;
      proxied = true;
      comment = null;
      priority = null;
    };
    music = {
      id = "165e4b06ec8c27ac99f5167106a2fa38";
      name = "music.lucc.dev";
      type = "CNAME";
      content = "music-6gm.pages.dev";
      ttl = 1;
      proxied = true;
      comment = null;
      priority = null;
    };
    slides = {
      id = "21078041f801e1c49d6171d0226760eb";
      name = "s.lucc.dev";
      type = "CNAME";
      content = "slides-6fn.pages.dev";
      ttl = 1;
      proxied = true;
      comment = null;
      priority = null;
    };
    mx_route3 = {
      id = "3bfffe44f3323a9fdbbb8b455622f113";
      name = "lucc.dev";
      type = "MX";
      content = "route3.mx.cloudflare.net";
      ttl = 1;
      proxied = false;
      comment = null;
      priority = 51;
    };
    mx_route2 = {
      id = "3cbcaf3176b7ea868a57dd13f47512c7";
      name = "lucc.dev";
      type = "MX";
      content = "route2.mx.cloudflare.net";
      ttl = 1;
      proxied = false;
      comment = null;
      priority = 38;
    };
    mx_route1 = {
      id = "e16cff5af9f8ec1e705fff3020a654f5";
      name = "lucc.dev";
      type = "MX";
      content = "route1.mx.cloudflare.net";
      ttl = 1;
      proxied = false;
      comment = null;
      priority = 67;
    };
    dkim = {
      id = "650591690a857966f1ca8242f4108ab3";
      name = "cf2024-1._domainkey.lucc.dev";
      type = "TXT";
      content = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\"";
      ttl = 1;
      proxied = false;
      comment = null;
      priority = null;
    };
    spf = {
      id = "8eadaa51a16abe012878207f99ae5d33";
      name = "lucc.dev";
      type = "TXT";
      content = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\"";
      ttl = 1;
      proxied = false;
      comment = null;
      priority = null;
    };
    dp = {
      id = "6bc3b7e5f9391562ac7df710c3578362";
      name = "dp.lucc.dev";
      type = "AAAA";
      content = "100::";
      ttl = 1;
      proxied = true;
      comment = null;
      priority = null;
    };
  };

  records = facts.dns.shared_records // manualRecords;
  importable = lib.filterAttrs (_: record: record.id != null) records;
in
{
  terraform = {
    required_version = ">= 1.8.0";

    required_providers.cloudflare = {
      source = "cloudflare/cloudflare";
      version = "~> 5.0";
    };

    backend.s3 = {
      bucket = "luck-dotfiles-opentofu-state";
      key = "homelab/cloudflare/lucc.dev/dns/terraform.tfstate";
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

  # 旧地址 -> for_each 地址的平滑迁移；与迁移前 HCL 完全一致。
  moved = [
    {
      from = "cloudflare_dns_record.atuin_lucc_dev_a_01";
      to = "cloudflare_dns_record.records[\"atuin\"]";
    }
    {
      from = "cloudflare_dns_record.beszel_lucc_dev_a_02";
      to = "cloudflare_dns_record.records[\"beszel\"]";
    }
    {
      from = "cloudflare_dns_record.mm_lucc_dev_a_05";
      to = "cloudflare_dns_record.records[\"memos\"]";
    }
    {
      from = "cloudflare_dns_record.n8n_lucc_dev_a_06";
      to = "cloudflare_dns_record.records[\"n8n\"]";
    }
    {
      from = "cloudflare_dns_record.pan_lucc_dev_a_07";
      to = "cloudflare_dns_record.records[\"openlist\"]";
    }
    {
      from = "cloudflare_dns_record.pt_lucc_dev_a_08";
      to = "cloudflare_dns_record.records[\"pt\"]";
    }
    {
      from = "cloudflare_dns_record.rsshub_lucc_dev_a_09";
      to = "cloudflare_dns_record.records[\"rsshub\"]";
    }
    {
      from = "cloudflare_dns_record.ts_lucc_dev_a_10";
      to = "cloudflare_dns_record.records[\"tailscale\"]";
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
      from = "cloudflare_dns_record.dokploy_lucc_dev_cname_15";
      to = "cloudflare_dns_record.records[\"dokploy\"]";
    }
    {
      from = "cloudflare_dns_record.lucc_dev_cname_16";
      to = "cloudflare_dns_record.records[\"root\"]";
    }
    {
      from = "cloudflare_dns_record.music_lucc_dev_cname_17";
      to = "cloudflare_dns_record.records[\"music\"]";
    }
    {
      from = "cloudflare_dns_record.s_lucc_dev_cname_18";
      to = "cloudflare_dns_record.records[\"slides\"]";
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
    {
      from = "cloudflare_dns_record.google_lucc_dev_aaaa_25";
      to = "cloudflare_dns_record.records[\"google\"]";
    }
  ];
}
