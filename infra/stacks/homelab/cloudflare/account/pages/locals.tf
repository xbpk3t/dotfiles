locals {
  account_id = "96540bd100b82adba941163704660c31"

  # Pages 里的 D1 binding 先直接引用 live database id，避免现在就引入跨 state output 依赖。
  # 等后续整个 Cloudflare 栈稳定以后，再考虑通过 remote state / globals 做统一编排。
  d1_database_ids = {
    vscs = "6f4f878f-4845-4801-9386-458c612f0a72"
  }

  # 这里开始使用 human-facing projects model。
  # 日常维护时优先改这个数据结构，而不是继续复制粘贴完整 resource blocks。
  pages_projects_managed = {
    blog = {
      name              = "blog"
      production_branch = "main"
      build_config = {
        build_caching       = null
        build_command       = ""
        destination_dir     = ""
        root_dir            = ""
        web_analytics_tag   = "c45f6e30b4744bb4a6a553d815e870f9"
        web_analytics_token = null
      }
      deployment_configs = {
        preview = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 3
          compatibility_date                   = "2025-11-27"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
        }
        production = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 3
          compatibility_date                   = "2025-11-27"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
        }
      }
      source = {
        type = "github"
        config = {
          owner                          = "xbpk3t"
          owner_id                       = "8591495"
          repo_name                      = "docs"
          repo_id                        = "711229681"
          production_branch              = "main"
          pr_comments_enabled            = true
          production_deployments_enabled = true
          preview_deployment_setting     = "all"
          preview_branch_includes        = ["*"]
          preview_branch_excludes        = []
          path_includes                  = ["*"]
          path_excludes                  = []
        }
      }
    }
    docs = {
      name              = "docs"
      production_branch = "gh-pages"
      build_config = {
        build_caching       = true
        build_command       = ""
        destination_dir     = ""
        root_dir            = ""
        web_analytics_tag   = "d6bce5f5b1694a4ab9b1f41d42af4a72"
        web_analytics_token = null
      }
      deployment_configs = {
        preview = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 2
          compatibility_date                   = "2023-10-24"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
        }
        production = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 2
          compatibility_date                   = "2023-10-24"
          compatibility_flags                  = []
          env_vars = var.pages_docs_cfp_pwd == null ? null : {
            CFP_PASSWORD = {
              type  = "plain_text"
              value = var.pages_docs_cfp_pwd
            }
          }
          fail_open = true
          placement = {
            mode = "smart"
          }
        }
      }
      source = {
        type = "github"
        config = {
          owner                          = "xbpk3t"
          owner_id                       = "8591495"
          repo_name                      = "docs"
          repo_id                        = "446885053"
          production_branch              = "gh-pages"
          pr_comments_enabled            = true
          production_deployments_enabled = true
          preview_deployment_setting     = "none"
          preview_branch_includes        = ["*"]
          preview_branch_excludes        = []
          path_includes                  = ["*"]
          path_excludes                  = []
        }
      }
    }
    me = {
      name              = "me"
      production_branch = "main"
      build_config = {
        build_caching       = null
        build_command       = null
        destination_dir     = null
        root_dir            = null
        web_analytics_tag   = "23d6ec54fe1f47879be87bdb210df6bf"
        web_analytics_token = null
      }
      deployment_configs = {
        preview = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 2
          compatibility_date                   = "2025-03-03"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
        }
        production = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 2
          compatibility_date                   = "2025-03-03"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
        }
      }
      source = null
    }


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
          compatibility_date                   = "2025-11-12"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
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
          preview_branch_includes        = ["*"]
          preview_branch_excludes        = []
          path_includes                  = ["*"]
          path_excludes                  = []
        }
      }

      notes = {
        crit = "high"
        des  = "长三角青少年小提琴艺术展演活动"
      }
    }
    slides = {
      name              = "slides"
      production_branch = "main"
      build_config = {
        build_caching       = null
        build_command       = ""
        destination_dir     = ""
        root_dir            = ""
        web_analytics_tag   = "9c83f3f6a81a47b789f1d1a8d2024e72"
        web_analytics_token = null
      }
      deployment_configs = {
        preview = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 3
          compatibility_date                   = "2025-08-31"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
        }
        production = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 3
          compatibility_date                   = "2025-08-31"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
        }
      }
      source = {
        type = "github"
        config = {
          owner                          = "xbpk3t"
          owner_id                       = "8591495"
          repo_name                      = "docs"
          repo_id                        = "711229681"
          production_branch              = "main"
          pr_comments_enabled            = true
          production_deployments_enabled = true
          preview_deployment_setting     = "all"
          preview_branch_includes        = ["*"]
          preview_branch_excludes        = []
          path_includes                  = ["*"]
          path_excludes                  = []
        }
      }
    }
  }

  # 这组项目当前目标是“先收编进 state，再在下一轮删除”。
  pages_projects_pending_delete = {
    nextflux = {
      name              = "nextflux"
      production_branch = "main"
      build_config = {
        build_caching       = null
        build_command       = "npm run build"
        destination_dir     = "dist"
        root_dir            = ""
        web_analytics_tag   = null
        web_analytics_token = null
      }
      deployment_configs = {
        preview = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 3
          compatibility_date                   = "2025-11-18"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
        }
        production = {
          always_use_latest_compatibility_date = false
          build_image_major_version            = 3
          compatibility_date                   = "2025-11-18"
          compatibility_flags                  = []
          env_vars                             = null
          fail_open                            = true
        }
      }
      source = {
        type = "github"
        config = {
          owner                          = "xbpk3t"
          owner_id                       = "8591495"
          repo_name                      = "nextflux"
          repo_id                        = "1098920099"
          production_branch              = "main"
          pr_comments_enabled            = true
          production_deployments_enabled = true
          preview_deployment_setting     = "all"
          preview_branch_includes        = ["*"]
          preview_branch_excludes        = []
          path_includes                  = ["*"]
          path_excludes                  = []
        }
      }
    }
  }

  pages_projects = merge(local.pages_projects_managed, local.pages_projects_pending_delete)
}
