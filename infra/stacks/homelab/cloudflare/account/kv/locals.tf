locals {
  account_id = "96540bd100b82adba941163704660c31"

  kv_namespaces_managed = {}

  # 第一轮 adopt 已完成，待删 namespace 已经进入 state。
  # 这里清空 pending_delete，第二轮 plan/apply 就会对 live 执行 destroy。
  kv_namespaces_pending_delete = {}

  kv_namespaces = merge(local.kv_namespaces_managed, local.kv_namespaces_pending_delete)
}
