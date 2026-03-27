stack {
  name        = "cloudflare-account-r2"
  description = "Cloudflare R2 buckets for the homelab account."
  tags = [
    "layer-infra",
    "env-homelab",
    "cloudflare",
    "account",
    "r2",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/cloudflare/account/r2"
}
