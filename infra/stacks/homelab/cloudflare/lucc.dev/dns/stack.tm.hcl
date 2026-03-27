stack {
  name        = "cloudflare-lucc-dev-dns"
  description = "Cloudflare DNS records for lucc.dev."
  tags = [
    "layer-infra",
    "env-homelab",
    "cloudflare",
    "dns",
    "zone-lucc-dev",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/cloudflare/lucc.dev/dns"
}
