locals {
  # D1 是 account-scope 资源，不属于某一个 zone。
  # 所以这里单独拆成 account 级别 state，避免和 DNS / Pages 混在一起。
  account_id = "96540bd100b82adba941163704660c31"

  d1_databases_managed = {
    docs = {
      uuid                  = "96375ee2-188f-44d4-ab16-eaa06828a4ac"
      name                  = "docs"
      jurisdiction          = null
      primary_location_hint = null
      read_replication_mode = "disabled"
    }

    # https://github.com/xbpk3t/zzz
    vscs = {
      uuid                  = "6f4f878f-4845-4801-9386-458c612f0a72"
      name                  = "vscs"
      jurisdiction          = null
      primary_location_hint = null
      read_replication_mode = "disabled"

      notes = {
        owner = "xbpk3t/zzz"
        crit  = "high"
        des   = "搭配 pages/music 项目"
      }
    }
  }

  # 第一轮 adopt 已完成，待删 database 已经进入 state。
  # 这里清空 pending_delete，第二轮 plan/apply 就会对 live 执行 destroy。
  d1_databases_pending_delete = {}

  d1_databases = merge(local.d1_databases_managed, local.d1_databases_pending_delete)
}
