stack {
  name        = "cloudflare-account-pages"
  description = "Cloudflare Pages projects for the homelab account."
  tags = [
    "layer-infra",
    "env-homelab",
    "cloudflare",
    "account",
    "pages",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/cloudflare/account/pages"
}
