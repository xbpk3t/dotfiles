resource "tailscale_acl" "main" {
  acl = jsonencode(merge(
    local.acl,
    { derpMap = local.derp_map }
  ))
}

resource "tailscale_dns_preferences" "main" {
  magic_dns = true
}

resource "tailscale_tailnet_key" "device_join" {
  reusable      = true
  ephemeral     = false
  preauthorized = false
  # 注意：provider v0.29.2 属性名是 expiry，不是 expiry_seconds
  # Tailscale API 硬限制 auth key 最长 90 天 (7776000s)，超过直接 400
  expiry = 7776000
}
