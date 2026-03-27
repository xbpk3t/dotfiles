# R2 bucket 的真正业务边界通常会和应用 / backup / assets 绑定。
# 这一版先按 bucket 粒度把现状收编进来，后续再考虑拆成更细的 ownership。

resource "cloudflare_r2_bucket" "buckets" {
  for_each = local.r2_buckets

  account_id = local.account_id
  name       = each.value.name
}
