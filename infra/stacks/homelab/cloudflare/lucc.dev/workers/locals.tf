locals {
  # Nix 生成的共享 infra facts；源文件 infra/facts.nix。
  facts = jsondecode(file("${path.module}/../../../../../generated/facts.json"))

  account_id = local.facts.cloudflare.account_id
  zone_id    = local.facts.cloudflare.zone_id
}
