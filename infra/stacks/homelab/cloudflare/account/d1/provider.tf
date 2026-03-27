provider "cloudflare" {
  # Cloudflare provider 默认从 CLOUDFLARE_API_TOKEN 读取 token。
  # 这里故意不把 token、account_id 硬编码进 provider block。
}
