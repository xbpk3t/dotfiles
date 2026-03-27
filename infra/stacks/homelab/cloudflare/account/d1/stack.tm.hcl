stack {
  name        = "cloudflare-account-d1"
  description = "Cloudflare D1 databases for the homelab account."
  tags = [
    "layer-infra",
    "env-homelab",
    "cloudflare",
    "account",
    "d1",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/cloudflare/account/d1"
}
