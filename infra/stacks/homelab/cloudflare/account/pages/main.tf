# Cloudflare Pages adopt 策略：
# 1. 先把 live project 配置固化成基线
# 2. 再通过 imports.tf 吸收到 state
# 3. 涉及 secret 的部分一律外置，不直接写进仓库

resource "cloudflare_pages_project" "projects" {
  for_each = local.pages_projects

  account_id         = local.account_id
  name               = each.value.name
  build_config       = each.value.build_config
  deployment_configs = each.value.deployment_configs
  production_branch  = each.value.production_branch
  source             = each.value.source
}

moved {
  from = cloudflare_pages_project.blog
  to   = cloudflare_pages_project.projects["blog"]
}

moved {
  from = cloudflare_pages_project.docs
  to   = cloudflare_pages_project.projects["docs"]
}

moved {
  from = cloudflare_pages_project.me
  to   = cloudflare_pages_project.projects["me"]
}

moved {
  from = cloudflare_pages_project.music
  to   = cloudflare_pages_project.projects["music"]
}

moved {
  from = cloudflare_pages_project.nextflux
  to   = cloudflare_pages_project.projects["nextflux"]
}

moved {
  from = cloudflare_pages_project.slides
  to   = cloudflare_pages_project.projects["slides"]
}
