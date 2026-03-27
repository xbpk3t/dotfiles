locals {
  # 当前这个 stack 只管理 lucc.dev 这个 zone 的 DNS。
  # 后续如果有第二个 zone，应该新建独立 stack，而不是混进同一个 state。
  zone_id   = "1c07a1b84d8273f4dfa6c3adce513f94"
  zone_name = "lucc.dev"

  # 这里开始使用 human-facing records model。
  # 日常维护时优先改这个数据结构，而不是继续手写一堆 resource blocks。
  dns_records_managed = {
    grafana = {
      id       = "0a78e1bf7e0d58ac35378f3c7e117625"
      name     = "g.lucc.dev"
      type     = "A"
      content  = "142.171.154.61"
      ttl      = 1
      proxied  = true
      comment  = "PAG- Grafana Dashboard"
      priority = null
    }
    k3s = {
      id       = "c159ba2bf018bcf724084f6db32b8f41"
      name     = "k3s.lucc.dev"
      type     = "A"
      content  = "142.171.154.61"
      ttl      = 1
      proxied  = true
      comment  = null
      priority = null
    }
    rsshub = {
      id       = "1eb043e1ffe747891513e47be11b0a6f"
      name     = "rsshub.lucc.dev"
      type     = "A"
      content  = "142.171.154.61"
      ttl      = 1
      proxied  = true
      comment  = "rsshub deploy by k3s"
      priority = null
    }
    tailscale = {
      id       = "b4a7143da983c688d9a1e3256c7fe08e"
      name     = "ts.lucc.dev"
      type     = "A"
      content  = "103.85.224.63"
      ttl      = 1
      proxied  = true
      comment  = "tailscale"
      priority = null
    }
    bc = {
      id       = "1bd30865c3c123a847e1a5f859ec5e0a"
      name     = "bc.lucc.dev"
      type     = "CNAME"
      content  = "public.r2.dev"
      ttl      = 1
      proxied  = true
      comment  = null
      priority = null
    }
    blog = {
      id       = "442d7dbf738b136ce33fea1048c4331c"
      name     = "blog.lucc.dev"
      type     = "CNAME"
      content  = "blog-cfg.pages.dev"
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
      id       = "1316b702e2113771137d9131d25f3d65"
      name     = "docs.lucc.dev"
      type     = "CNAME"
      content  = "docs-fq6.pages.dev"
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
  dns_records = merge(local.dns_records_managed, local.dns_records_pending_delete)
}
