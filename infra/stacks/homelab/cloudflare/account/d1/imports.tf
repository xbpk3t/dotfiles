# 这些 import blocks 用来把现有 D1 数据库吸收到 state。
# 这里直接跟随 `locals.d1_databases` 自动展开，避免静态 imports 漂移。

import {
  for_each = local.d1_databases

  to = cloudflare_d1_database.databases[each.key]
  id = "${local.account_id}/${each.value.uuid}"
}
