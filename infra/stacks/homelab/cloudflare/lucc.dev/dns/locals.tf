locals {
  # Nix 生成的共享 infra facts：account/zone id 与由 host meta 派生的 DNS 记录。
  # 源文件 infra/facts.nix；重新生成用 `task tf:facts`。
  facts = jsondecode(file("${path.module}/../../../../../generated/facts.json"))

  # 当前这个 stack 只管理 lucc.dev 这个 zone 的 DNS。
  # 后续如果有第二个 zone，应该新建独立 stack，而不是混进同一个 state。
  zone_id   = local.facts.cloudflare.zone_id
  zone_name = local.facts.cloudflare.zone_name

  # Nix facts 派生记录（api/as/rsshub/derp-dev/nva/derp-sm-vps-tc）。
  dns_records_from_nix = local.facts.dns.shared_records

  # 手写记录：外部服务 / Pages / Email Routing 等 provider 细节较多，
  # 暂不进入 Nix facts。
  dns_records_manual = {
    blog = {
      id       = "db66877fcacde96aa9844c8a91ec3a16"
      name     = "blog.lucc.dev"
      type     = "AAAA"
      content  = "100::"
      ttl      = 1
      proxied  = true
      comment  = null
      priority = null
    }
    cdn = {
      id       = "68bf0f40f96ff96acbd75a119e988750"
      name     = "cdn.lucc.dev"
      type     = "CNAME"
      content  = "public.r2.dev"
      ttl      = 1
      proxied  = true
      comment  = null
      priority = null
    }
    docs = {
      id       = "056c4cc7e02dfac9d69c9ff02d522314"
      name     = "docs.lucc.dev"
      type     = "AAAA"
      content  = "100::"
      ttl      = 1
      proxied  = true
      comment  = null
      priority = null
    }
    root = {
      id       = "a80a731e11c54cc0a9707b454b0dea63"
      name     = "lucc.dev"
      type     = "CNAME"
      content  = "me-4b9.pages.dev"
      ttl      = 1
      proxied  = true
      comment  = null
      priority = null
    }
    music = {
      id       = "165e4b06ec8c27ac99f5167106a2fa38"
      name     = "music.lucc.dev"
      type     = "CNAME"
      content  = "music-6gm.pages.dev"
      ttl      = 1
      proxied  = true
      comment  = null
      priority = null
    }
    slides = {
      id       = "21078041f801e1c49d6171d0226760eb"
      name     = "s.lucc.dev"
      type     = "CNAME"
      content  = "slides-6fn.pages.dev"
      ttl      = 1
      proxied  = true
      comment  = null
      priority = null
    }
    mx_route3 = {
      id       = "3bfffe44f3323a9fdbbb8b455622f113"
      name     = "lucc.dev"
      type     = "MX"
      content  = "route3.mx.cloudflare.net"
      ttl      = 1
      proxied  = false
      comment  = null
      priority = 51
    }
    mx_route2 = {
      id       = "3cbcaf3176b7ea868a57dd13f47512c7"
      name     = "lucc.dev"
      type     = "MX"
      content  = "route2.mx.cloudflare.net"
      ttl      = 1
      proxied  = false
      comment  = null
      priority = 38
    }
    mx_route1 = {
      id       = "e16cff5af9f8ec1e705fff3020a654f5"
      name     = "lucc.dev"
      type     = "MX"
      content  = "route1.mx.cloudflare.net"
      ttl      = 1
      proxied  = false
      comment  = null
      priority = 67
    }
    dkim = {
      id       = "650591690a857966f1ca8242f4108ab3"
      name     = "cf2024-1._domainkey.lucc.dev"
      type     = "TXT"
      content  = "\"v=DKIM1; h=sha256; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiweykoi+o48IOGuP7GR3X0MOExCUDY/BCRHoWBnh3rChl7WhdyCxW3jgq1daEjPPqoi7sJvdg5hEQVsgVRQP4DcnQDVjGMbASQtrY4WmB1VebF+RPJB2ECPsEDTpeiI5ZyUAwJaVX7r6bznU67g7LvFq35yIo4sdlmtZGV+i0H4cpYH9+3JJ78k\" \"m4KXwaf9xUJCWF6nxeD+qG6Fyruw1Qlbds2r85U9dkNDVAS3gioCvELryh1TxKGiVTkg4wqHTyHfWsp7KD3WQHYJn0RyfJJu6YEmL77zonn7p2SRMvTMP3ZEXibnC9gz3nnhR6wcYL8Q7zXypKTMD58bTixDSJwIDAQAB\""
      ttl      = 1
      proxied  = false
      comment  = null
      priority = null
    }
    spf = {
      id       = "8eadaa51a16abe012878207f99ae5d33"
      name     = "lucc.dev"
      type     = "TXT"
      content  = "\"v=spf1 include:_spf.mx.cloudflare.net ~all\""
      ttl      = 1
      proxied  = false
      comment  = null
      priority = null
    }
    dp = {
      id       = "6bc3b7e5f9391562ac7df710c3578362"
      name     = "dp.lucc.dev"
      type     = "AAAA"
      content  = "100::"
      ttl      = 1
      proxied  = true
      comment  = null
      priority = null
    }
  }

  # 这组资源目前的目标是“先收编进 state，再在下一轮删除”。
  # Why:
  # 1. 它们现在仍然存在于 Cloudflare live
  # 2. 但还没有进 state，直接删掉注释并不会触发 destroy
  # 第一轮 adopt 已完成，待删 records 已经进入 state。
  # 这里清空 pending_delete，第二轮 plan/apply 就会对 live 执行 destroy。
  dns_records_pending_delete = {}

  # google 这条记录已经不在 live 里了，所以继续排除，不放进 pending_delete。
  dns_records = merge(
    local.dns_records_from_nix,
    local.dns_records_manual,
    local.dns_records_pending_delete
  )
}
