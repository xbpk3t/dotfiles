# 这些 import blocks 用来把现有 dashboard 里的 DNS 记录吸收到 state。
# 这里直接跟随 `locals.dns_records` 自动展开，避免 imports.tf 和 locals.tf 再次漂移。

import {
  for_each = local.dns_records

  to = cloudflare_dns_record.records[each.key]
  id = "${local.zone_id}/${each.value.id}"
}
