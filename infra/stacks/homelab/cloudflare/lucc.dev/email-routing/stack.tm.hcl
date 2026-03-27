stack {
  name        = "cloudflare-lucc-dev-email-routing"
  description = "Cloudflare Email Routing rules for lucc.dev."
  tags = [
    "layer-infra",
    "env-homelab",
    "cloudflare",
    "email-routing",
    "zone-lucc-dev",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/cloudflare/lucc.dev/email-routing"
}
