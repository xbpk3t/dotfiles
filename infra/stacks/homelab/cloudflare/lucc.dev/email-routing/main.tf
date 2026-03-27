# 这里先只纳管 Email Routing rules。
# MX / SPF / DKIM 这类验证记录已经在 dns stack 中管理，避免同一组 DNS records 被两个 state 同时声明。

resource "cloudflare_email_routing_rule" "forward_me" {
  zone_id  = local.zone_id
  name     = "Rule created at 2025-02-20T06:52:34.085Z"
  enabled  = true
  priority = 0

  # 这里保留 Cloudflare 当前 live 配置，先做 adopt，不在第一步改语义。
  matchers = [
    {
      type  = "literal"
      field = "to"
      value = "me@lucc.dev"
    },
  ]

  actions = [
    {
      type = "forward"
      value = [
        "jeffcottlu@gmail.com",
      ]
    },
  ]
}

resource "cloudflare_email_routing_catch_all" "default_drop" {
  zone_id = local.zone_id
  enabled = false

  # 这里保留 Cloudflare 当前 live 配置，先做 adopt，不在第一步改语义。
  matchers = [
    {
      type = "all"
    },
  ]

  actions = [
    {
      type = "drop"
    },
  ]
}
