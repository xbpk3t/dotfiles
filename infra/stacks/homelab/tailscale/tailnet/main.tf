resource "tailscale_acl" "main" {
  acl = jsonencode(merge(
    local.acl,
    { derpMap = local.derp_map }
  ))
}

resource "tailscale_dns_preferences" "main" {
  magic_dns = true
}

# 9router dashboard: Tailscale Service -> http://9router.tailf19540.ts.net/
# Host side: services.tailscale.serve.services."9router".endpoints."tcp:80"
# = http://127.0.0.1:20228 (hosts/nixos-vps/default.nix).
# Use tcp:80 so the URL has no explicit port; the current NixOS module cannot
# request HTTPS termination for Service endpoints (nixpkgs#530174).
resource "tailscale_service" "ninerouter" {
  name    = "svc:9router"
  comment = "9router dashboard (HTTP over tailnet)"
  ports   = ["tcp:80"]
}

# Nezha dashboard: Tailscale Service -> http://nezha.tailf19540.ts.net/
# Host side: services.tailscale.serve.services."nezha".endpoints."tcp:80"
# = http://127.0.0.1:8008 (hosts/nixos-vps/default.nix).
resource "tailscale_service" "nezha" {
  name    = "svc:nezha"
  comment = "Nezha dashboard (HTTP over tailnet)"
  ports   = ["tcp:80"]
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

# Tailscale Services 要求 service host 是 tagged device。
# 只给 nixos-vps-dev 打专用 tag；tag owner / autoApprovers 见 locals.tf。
# 注意：tagging 会把设备 owner 从 user 改为 tag，所以 ACL 里同时把
# tag:svc-9router 加进 exitNode/routes autoApprovers，避免 exit node 回归。
resource "tailscale_device_tags" "nixos_vps_dev" {
  device_id = data.tailscale_device.servers["nixos-vps-dev"].id
  tags      = ["tag:svc-9router"]

  # tagOwners 必须先由 tailscale_acl 写入，设备 tag 才被接受（否则 API 400）。
  depends_on = [tailscale_acl.main]
}

resource "tailscale_device_key" "servers" {
  for_each            = data.tailscale_device.servers
  device_id           = each.value.id
  key_expiry_disabled = true
}
