# KV namespace 属于 account-scope 资源。
# 这里先把 live namespace 收编进 state，后续再根据实际用途决定是否拆 module 或命名规范。

resource "cloudflare_workers_kv_namespace" "namespaces" {
  for_each = local.kv_namespaces

  account_id = local.account_id
  title      = each.value.title
}
