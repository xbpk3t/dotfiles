# 这些 import blocks 用来把现有 dashboard 里的 DNS 记录吸收到 state。
# 这里直接跟随 `locals.dns_records` 自动展开，避免 imports.tf 和 locals.tf 再次漂移。

import {

  # 否则只有 id != null 的record才会走 import（否则你在配置之前一定不知道id，需要先去 cf dashboard 手动建一遍，在fetch到本地）
  for_each = {
    for key, record in local.dns_records : key => record
    if try(record.id, null) != null
  }

  to = cloudflare_dns_record.records[each.key]
  id = "${local.zone_id}/${each.value.id}"
}
