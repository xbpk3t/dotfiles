# import blocks 跟随当前的 `locals.r2_buckets` 自动展开。
# 这样当你在 locals 里注释掉某个 bucket 时，不会再出现“import target 不存在”的漂移。

import {
  for_each = local.r2_buckets

  to = cloudflare_r2_bucket.buckets[each.key]
  id = "${local.account_id}/${each.value.name}/default"
}
