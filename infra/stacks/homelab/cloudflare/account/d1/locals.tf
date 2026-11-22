locals {
  # Nix 生成的共享 infra facts；源文件 infra/facts.nix。
  facts = jsondecode(file("${path.module}/../../../../../generated/facts.json"))

  # D1 是 account-scope 资源，不属于某一个 zone。
  # 所以这里单独拆成 account 级别 state，避免和 DNS / Pages 混在一起。
  account_id = local.facts.cloudflare.account_id

  d1_databases_managed = {
    docs = {
      uuid                  = local.facts.cloudflare.d1.docs.id
      name                  = local.facts.cloudflare.d1.docs.name
      jurisdiction          = null
      primary_location_hint = null
      read_replication_mode = "disabled"
    }

    # https://github.com/xbpk3t/zzz
    vscs = {
      uuid                  = local.facts.cloudflare.d1.vscs.id
      name                  = local.facts.cloudflare.d1.vscs.name
      jurisdiction          = null
      primary_location_hint = null
      read_replication_mode = "disabled"

      notes = {
        owner = "xbpk3t/zzz"
        crit  = "high"
        des   = "搭配 Workers music 项目"
      }
    }
  }

  # 第一轮 adopt 已完成，待删 database 已经进入 state。
  # 这里清空 pending_delete，第二轮 plan/apply 就会对 live 执行 destroy。
  d1_databases_pending_delete = {}

  d1_databases = merge(local.d1_databases_managed, local.d1_databases_pending_delete)
}
