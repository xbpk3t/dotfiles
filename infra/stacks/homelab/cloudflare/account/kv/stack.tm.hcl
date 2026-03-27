stack {
  name        = "cloudflare-account-kv"
  description = "Cloudflare KV namespaces for the homelab account."
  tags = [
    "layer-infra",
    "env-homelab",
    "cloudflare",
    "account",
    "kv",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/cloudflare/account/kv"
}
