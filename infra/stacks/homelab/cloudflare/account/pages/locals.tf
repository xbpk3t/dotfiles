locals {
  # Nix 生成的共享 infra facts；源文件 infra/facts.nix。
  facts = jsondecode(file("${path.module}/../../../../../generated/facts.json"))

  account_id = local.facts.cloudflare.account_id

  # Pages 已全部迁出：
  # - blog / docs / me 早已迁到 Workers
  # - music 已迁到 Workers（infra/stacks/homelab/cloudflare/lucc.dev/workers）
  # 这里保留空 stack 作为历史锚点；确认不再需要 Pages 后可以整体删除。
  pages_projects = {}
}
