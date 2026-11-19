# 这里先只纳管 Email Routing rules。
# MX / SPF / DKIM 这类验证记录已经在 dns stack 中管理，避免同一组 DNS records 被两个 state 同时声明。

resource "cloudflare_email_routing_rule" "forward_me" {
  zone_id  = local.zone_id
  name     = "Rule created at 2025-02-20T06:52:34.085Z"
  enabled  = true
  priority = 0

  # me@lucc.dev 转发到 Gmail；对应规则保持启用。
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

# 注意：catch-all（当前 live = disabled + drop）有意不由 Terraform 管理。
#
# Why: provider v5 的 cloudflare_email_routing_catch_all.tag 是 computed-only，
# 每次 plan 都会出现 "tag -> (known after apply)" 的永久 diff，导致 GitOps
# drift 永远报红（v5.18.0 与 v5.29.0 都复现）。
#
# live 配置已固定为 disabled + drop；需要修改时走 Dashboard 或 API。如果
# provider 后续修复，可以重新加回 resource + import。
#
# state 处理：catch-all 已通过 `tofu state rm` 从 remote state 移除，
# 当前 plan 不再包含它；live 保持 disabled + drop，不执行 destroy。
