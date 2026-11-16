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

# 基础设施节点关闭 device key expiry。
# Why：ssh/deploy 统一走 tailnet 后，节点 key 过期 = 同时失去 SSH 与 deploy，
# 只剩云控制台下 VNC。tailnet 是唯一入口的机器必须常驻。
# 不用 tag:server 的原因：tagging 会改变设备 owner，破坏 ACL 里的
# autogroup:self（agt 的手机 Tailscale SSH）和基于用户身份的 exit node autoApprovers。
data "tailscale_device" "servers" {
  for_each = toset([
    "nixos-vps-dev",
    "nixos-vps-agt",
  ])
  hostname = each.key
}

resource "tailscale_device_key" "servers" {
  for_each            = data.tailscale_device.servers
  device_id           = each.value.id
  key_expiry_disabled = true
}
