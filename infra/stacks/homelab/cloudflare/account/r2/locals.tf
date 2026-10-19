locals {
  account_id = "96540bd100b82adba941163704660c31"

  # 1. resource-facing 字段
  #    name, title, uuid, read_replication_mode 这种 provider 真正会用到的
  # 2. human-facing notes
  #    这里只是给人看的备注，不会传给 provider
  #    你后续可以继续在 notes 里补 owner / des / usage 之类的信息

  # backend 使用的 `luck-dotfiles-opentofu-state` bucket 故意不放进这里。
  # Why:
  # 1. 它属于 bootstrap resource，必须先于当前 stack 存在
  # 2. 如果把它和自己的 remote state 放进同一个自举流程，会形成循环依赖
  # 当前 inventory 只拿到了 bucket 名称。
  # `location` / `storage_class` / `jurisdiction` 这类属性 provider 会从 live state 读回，
  # 所以这里先保持最小声明，先完成 adopt，再做更细的策略化整理。
  r2_buckets_managed = {

    docs = {
      name = "docs"
      notes = {
        crit  = "high"
        owner = "docs"
        des   = "docs-images"
      }
    }
  }

  # 第一轮 adopt 已完成，待删 buckets 已经进入 state。
  # 这里清空 pending_delete，第二轮 plan/apply 就会对 live 执行 destroy。
  r2_buckets_pending_delete = {}

  r2_buckets = merge(local.r2_buckets_managed, local.r2_buckets_pending_delete)
}
