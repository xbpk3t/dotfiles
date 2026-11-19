locals {
  # Nix 生成的共享 infra facts；源文件 infra/facts.nix。
  facts = jsondecode(file("${path.module}/../../../../../generated/facts.json"))

  account_id = local.facts.cloudflare.account_id

  # Pages 里的 D1 binding 先直接引用 live database id，避免现在就引入跨 state output 依赖。
  # 等后续整个 Cloudflare 栈稳定以后，再考虑通过 remote state / globals 做统一编排。
  d1_database_ids = {
    vscs = "6f4f878f-4845-4801-9386-458c612f0a72"
  }

  # pages_projects_managed 只保留仍在用的 music。
  # blog / docs / me 已经迁到 Workers routes，slides project 已删除，
  # nextflux 也已从 state 移除。music 计划后续迁到 Workers；迁移完成前
  # 继续由 Pages 管理，保证站点不中断。
  pages_projects_managed = {
    music = {
      name              = "music"
      production_branch = "gh-pages"
      build_config = {
        build_caching       = null
        build_command       = ""
        destination_dir     = "dist"
        root_dir            = ""
        web_analytics_tag   = null
        web_analytics_token = null
      }
      deployment_configs = {
        preview = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 3
          compatibility_date                   = "2025-11-17"
          compatibility_flags                  = []
          env_vars                             = {}
          d1_databases = {
            DB = {
              id = local.d1_database_ids.vscs
            }
          }
          fail_open            = true
          wrangler_config_hash = "4b80cbe3a76bfc7f6c1e67d5fe86ecc6921786292b1ecf9ad418989e78aa0ef9"
        }
        production = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 3
          compatibility_date                   = "2025-11-17"
          compatibility_flags                  = []
          env_vars                             = {}
          d1_databases = {
            DB = {
              id = local.d1_database_ids.vscs
            }
          }
          fail_open            = true
          wrangler_config_hash = "4b80cbe3a76bfc7f6c1e67d5fe86ecc6921786292b1ecf9ad418989e78aa0ef9"
        }
      }
      source = {
        type = "github"
        config = {
          owner                          = "xbpk3t"
          owner_id                       = "8591495"
          repo_name                      = "zzz"
          repo_id                        = "878906090"
          production_branch              = "gh-pages"
          pr_comments_enabled            = true
          production_deployments_enabled = true
          preview_deployment_setting     = "all"
          # 不要显式写 path_excludes / preview_branch_excludes = []：
          # provider v5 会把空列表读回 null，apply 后报 inconsistent result。
          preview_branch_includes = ["*"]
          path_includes           = ["*"]
        }
      }

      notes = {
        crit = "high"
        des  = "长三角青少年小提琴艺术展演活动"
      }
    }
  }

  # 这组项目当前目标是“先收编进 state，再在下一轮删除”。
  pages_projects_pending_delete = {}

  pages_projects = merge(local.pages_projects_managed, local.pages_projects_pending_delete)
}
