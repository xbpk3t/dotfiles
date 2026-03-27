import {
  for_each = local.kv_namespaces

  to = cloudflare_workers_kv_namespace.namespaces[each.key]
  id = "${local.account_id}/${each.value.id}"
}
