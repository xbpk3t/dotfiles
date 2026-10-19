# import blocks 只跟随“已 adopt”的 bucket 自动展开（managed ∪ pending_delete）。
# 这样当你在 locals 里注释掉某个 bucket 时，不会再出现“import target 不存在”的漂移。
# r2_buckets_created 里的 bucket 由 TF 首建，不生成 import 块（对象尚不存在，import 会失败）。

import {
  for_each = merge(local.r2_buckets_managed, local.r2_buckets_pending_delete)

  to = cloudflare_r2_bucket.buckets[each.key]
  id = "${local.account_id}/${each.value.name}/default"
}
