# Workers custom domains for lucc.dev.
#
# 目前只有 music：Worker 脚本由 zzz repo 的 CI 部署，infra 只负责域名/DNS
# ownership。custom domain 由 Cloudflare 自动创建/接管 DNS 记录和证书。
resource "cloudflare_workers_custom_domain" "music" {
  account_id = local.account_id
  zone_id    = local.zone_id
  hostname   = "music.lucc.dev"
  service    = "music"
}
