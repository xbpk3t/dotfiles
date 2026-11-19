provider "tailscale" {
  tailnet = local.facts.tailscale.tailnet
  # api_key 从 TAILSCALE_API_KEY 环境变量自动读取
}
