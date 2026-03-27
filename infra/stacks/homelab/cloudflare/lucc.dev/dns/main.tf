# Cloudflare DNS adopt 策略：
# 1. 先按 live inventory 把现状声明进来
# 2. 再通过 imports.tf 把现有记录纳入 state
# 3. 第一次目标是 no-op plan，而不是顺手改记录语义

resource "cloudflare_dns_record" "records" {
  for_each = local.dns_records

  zone_id  = local.zone_id
  name     = each.value.name
  ttl      = each.value.ttl
  type     = each.value.type
  content  = each.value.content
  proxied  = each.value.proxied
  comment  = each.value.comment
  priority = each.value.priority
}

# 如果本地 state 里已经存在旧地址，下面这些 moved blocks 会把它们平滑迁移到新的 for_each 地址。
moved {
  from = cloudflare_dns_record.atuin_lucc_dev_a_01
  to   = cloudflare_dns_record.records["atuin"]
}

moved {
  from = cloudflare_dns_record.beszel_lucc_dev_a_02
  to   = cloudflare_dns_record.records["beszel"]
}

moved {
  from = cloudflare_dns_record.g_lucc_dev_a_03
  to   = cloudflare_dns_record.records["grafana"]
}

moved {
  from = cloudflare_dns_record.k3s_lucc_dev_a_04
  to   = cloudflare_dns_record.records["k3s"]
}

moved {
  from = cloudflare_dns_record.mm_lucc_dev_a_05
  to   = cloudflare_dns_record.records["memos"]
}

moved {
  from = cloudflare_dns_record.n8n_lucc_dev_a_06
  to   = cloudflare_dns_record.records["n8n"]
}

moved {
  from = cloudflare_dns_record.pan_lucc_dev_a_07
  to   = cloudflare_dns_record.records["openlist"]
}

moved {
  from = cloudflare_dns_record.pt_lucc_dev_a_08
  to   = cloudflare_dns_record.records["pt"]
}

moved {
  from = cloudflare_dns_record.rsshub_lucc_dev_a_09
  to   = cloudflare_dns_record.records["rsshub"]
}

moved {
  from = cloudflare_dns_record.ts_lucc_dev_a_10
  to   = cloudflare_dns_record.records["tailscale"]
}

moved {
  from = cloudflare_dns_record.bc_lucc_dev_cname_11
  to   = cloudflare_dns_record.records["bc"]
}

moved {
  from = cloudflare_dns_record.blog_lucc_dev_cname_12
  to   = cloudflare_dns_record.records["blog"]
}

moved {
  from = cloudflare_dns_record.cdn_lucc_dev_cname_13
  to   = cloudflare_dns_record.records["cdn"]
}

moved {
  from = cloudflare_dns_record.docs_lucc_dev_cname_14
  to   = cloudflare_dns_record.records["docs"]
}

moved {
  from = cloudflare_dns_record.dokploy_lucc_dev_cname_15
  to   = cloudflare_dns_record.records["dokploy"]
}

moved {
  from = cloudflare_dns_record.lucc_dev_cname_16
  to   = cloudflare_dns_record.records["root"]
}

moved {
  from = cloudflare_dns_record.music_lucc_dev_cname_17
  to   = cloudflare_dns_record.records["music"]
}

moved {
  from = cloudflare_dns_record.s_lucc_dev_cname_18
  to   = cloudflare_dns_record.records["slides"]
}

moved {
  from = cloudflare_dns_record.lucc_dev_mx_19
  to   = cloudflare_dns_record.records["mx_route3"]
}

moved {
  from = cloudflare_dns_record.lucc_dev_mx_20
  to   = cloudflare_dns_record.records["mx_route2"]
}

moved {
  from = cloudflare_dns_record.lucc_dev_mx_21
  to   = cloudflare_dns_record.records["mx_route1"]
}

moved {
  from = cloudflare_dns_record.cf2024_1_domainkey_lucc_dev_txt_22
  to   = cloudflare_dns_record.records["dkim"]
}

moved {
  from = cloudflare_dns_record.lucc_dev_txt_23
  to   = cloudflare_dns_record.records["spf"]
}

moved {
  from = cloudflare_dns_record.dp_lucc_dev_aaaa_24
  to   = cloudflare_dns_record.records["dp"]
}

moved {
  from = cloudflare_dns_record.google_lucc_dev_aaaa_25
  to   = cloudflare_dns_record.records["google"]
}
