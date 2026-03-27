# Cloudflare D1 adopt 策略：
# 1. 先按 live inventory 把现状声明进来
# 2. 再通过 imports.tf 把现有数据库纳入 state
# 3. 第一次目标是 no-op plan，而不是顺手改 schema / placement

resource "cloudflare_d1_database" "databases" {
  for_each = local.d1_databases

  account_id            = local.account_id
  name                  = each.value.name
  jurisdiction          = each.value.jurisdiction
  primary_location_hint = each.value.primary_location_hint

  read_replication = {
    mode = each.value.read_replication_mode
  }
}
