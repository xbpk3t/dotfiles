locals {
  owner = "xbpk3t"

  # Core repositories with direct coupling to this infra repo, Cloudflare Pages,
  # Flux, or the current personal automation surface.
  repositories = {
    dotfiles = {
      name                        = "dotfiles"
      description                 = ""
      homepage_url                = ""
      visibility                  = "public"
      archived                    = false
      has_issues                  = true
      has_projects                = true
      has_wiki                    = true
      has_discussions             = false
      is_template                 = false
      allow_merge_commit          = true
      allow_squash_merge          = true
      allow_rebase_merge          = true
      allow_auto_merge            = false
      allow_update_branch         = false
      allow_forking               = true
      delete_branch_on_merge      = false
      web_commit_signoff_required = false
      merge_commit_title          = "MERGE_MESSAGE"
      merge_commit_message        = "PR_TITLE"
      squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
      squash_merge_commit_message = "COMMIT_MESSAGES"
      topics                      = ["nix", "nixos", "nixos-configuration"]
      workflow_permission         = "read"
      actions_enabled             = true
      actions_allowed             = "all"
      can_approve_pull_requests   = false
      private_branch_protection   = false
      desired_branch_protection   = "light"
      actions_secrets             = []
    }

    docs = {
      name                        = "docs"
      description                 = ""
      homepage_url                = "https://docs.lucc.dev/"
      visibility                  = "private"
      archived                    = false
      has_issues                  = true
      has_projects                = false
      has_wiki                    = false
      has_discussions             = false
      is_template                 = false
      allow_merge_commit          = true
      allow_squash_merge          = true
      allow_rebase_merge          = true
      allow_auto_merge            = false
      allow_update_branch         = false
      allow_forking               = true
      delete_branch_on_merge      = false
      web_commit_signoff_required = false
      merge_commit_title          = "MERGE_MESSAGE"
      merge_commit_message        = "PR_TITLE"
      squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
      squash_merge_commit_message = "COMMIT_MESSAGES"
      topics                      = []
      workflow_permission         = "write"
      actions_enabled             = true
      actions_allowed             = "all"
      can_approve_pull_requests   = false
      private_branch_protection   = true
      desired_branch_protection   = "blocked-by-github-pro"
      actions_secrets = [
        "CF_ACCOUNT_ID",
        "CF_API_TOKEN",
        "EXA_API_KEY",
        "KEENABLE_API_KEY",
        "PAT",
        "QUANT_SYNC_TOKEN",
        "R2_ACCOUNT",
        "R2_AK",
        "R2_KEY",
        "RESEND_TOKEN",
        "TAVILY_API_KEY",
        "TOKEN",
      ]
    }

    zzz = {
      name                        = "zzz"
      description                 = ""
      homepage_url                = ""
      visibility                  = "private"
      archived                    = false
      has_issues                  = true
      has_projects                = true
      has_wiki                    = false
      has_discussions             = false
      is_template                 = false
      allow_merge_commit          = true
      allow_squash_merge          = true
      allow_rebase_merge          = true
      allow_auto_merge            = false
      allow_update_branch         = false
      allow_forking               = true
      delete_branch_on_merge      = false
      web_commit_signoff_required = false
      merge_commit_title          = "MERGE_MESSAGE"
      merge_commit_message        = "PR_TITLE"
      squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
      squash_merge_commit_message = "COMMIT_MESSAGES"
      topics                      = []
      workflow_permission         = "read"
      actions_enabled             = true
      actions_allowed             = "all"
      can_approve_pull_requests   = false
      private_branch_protection   = true
      desired_branch_protection   = "blocked-by-github-pro"
      actions_secrets             = ["CF_ACCOUNT_ID", "CF_API_TOKEN"]
    }

    me = {
      name                        = "me"
      description                 = ""
      homepage_url                = "https://lucc.dev/"
      visibility                  = "private"
      archived                    = false
      has_issues                  = true
      has_projects                = true
      has_wiki                    = false
      has_discussions             = false
      is_template                 = false
      allow_merge_commit          = true
      allow_squash_merge          = true
      allow_rebase_merge          = true
      allow_auto_merge            = false
      allow_update_branch         = false
      allow_forking               = true
      delete_branch_on_merge      = false
      web_commit_signoff_required = false
      merge_commit_title          = "MERGE_MESSAGE"
      merge_commit_message        = "PR_TITLE"
      squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
      squash_merge_commit_message = "COMMIT_MESSAGES"
      topics                      = []
      workflow_permission         = "read"
      actions_enabled             = true
      actions_allowed             = "all"
      can_approve_pull_requests   = false
      private_branch_protection   = true
      desired_branch_protection   = "blocked-by-github-pro"
      actions_secrets             = ["CF_ACCOUNT_ID", "CF_API_TOKEN"]
    }

    wiki = {
      name                        = "wiki"
      description                 = "Personal wiki research workspace \u2014 rss2nl digest output"
      homepage_url                = ""
      visibility                  = "private"
      archived                    = false
      has_issues                  = true
      has_projects                = true
      has_wiki                    = false
      has_discussions             = false
      is_template                 = false
      allow_merge_commit          = true
      allow_squash_merge          = true
      allow_rebase_merge          = true
      allow_auto_merge            = false
      allow_update_branch         = false
      allow_forking               = true
      delete_branch_on_merge      = false
      web_commit_signoff_required = false
      merge_commit_title          = "MERGE_MESSAGE"
      merge_commit_message        = "PR_TITLE"
      squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
      squash_merge_commit_message = "COMMIT_MESSAGES"
      topics                      = []
      workflow_permission         = "read"
      actions_enabled             = true
      actions_allowed             = "all"
      can_approve_pull_requests   = false
      private_branch_protection   = true
      desired_branch_protection   = "blocked-by-github-pro"
      actions_secrets             = []
    }

    quant = {
      name                        = "quant"
      description                 = "Python quant project mirrored from docs/quant"
      homepage_url                = ""
      visibility                  = "private"
      archived                    = false
      has_issues                  = false
      has_projects                = true
      has_wiki                    = false
      has_discussions             = false
      is_template                 = false
      allow_merge_commit          = true
      allow_squash_merge          = true
      allow_rebase_merge          = true
      allow_auto_merge            = false
      allow_update_branch         = false
      allow_forking               = true
      delete_branch_on_merge      = false
      web_commit_signoff_required = false
      merge_commit_title          = "MERGE_MESSAGE"
      merge_commit_message        = "PR_TITLE"
      squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
      squash_merge_commit_message = "COMMIT_MESSAGES"
      topics                      = []
      workflow_permission         = "read"
      actions_enabled             = true
      actions_allowed             = "all"
      can_approve_pull_requests   = false
      private_branch_protection   = true
      desired_branch_protection   = "blocked-by-github-pro"
      actions_secrets             = []
    }
  }

  environments = {
    docs_production = {
      repository          = "docs"
      environment         = "docs (Production)"
      can_admins_bypass   = true
      prevent_self_review = false
    }
    zzz_production = {
      repository          = "zzz"
      environment         = "production"
      can_admins_bypass   = true
      prevent_self_review = false
    }
  }

  # Inventory only. Do not create github_actions_secret resources in this stack;
  # GitHub cannot read secret values back and Terraform state would become part
  # of the secret blast radius.
  secret_inventory = {
    for repo, cfg in local.repositories : repo => cfg.actions_secrets
  }
}
