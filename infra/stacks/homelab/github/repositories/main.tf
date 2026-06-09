resource "github_repository" "repositories" {
  for_each = local.repositories

  name                        = each.value.name
  description                 = each.value.description
  homepage_url                = each.value.homepage_url
  visibility                  = each.value.visibility
  archived                    = each.value.archived
  has_issues                  = each.value.has_issues
  has_projects                = each.value.has_projects
  has_wiki                    = each.value.has_wiki
  has_discussions             = each.value.has_discussions
  is_template                 = each.value.is_template
  allow_merge_commit          = each.value.allow_merge_commit
  allow_squash_merge          = each.value.allow_squash_merge
  allow_rebase_merge          = each.value.allow_rebase_merge
  allow_auto_merge            = each.value.allow_auto_merge
  allow_update_branch         = each.value.allow_update_branch
  allow_forking               = each.value.allow_forking
  delete_branch_on_merge      = each.value.delete_branch_on_merge
  web_commit_signoff_required = each.value.web_commit_signoff_required
  merge_commit_title          = each.value.merge_commit_title
  merge_commit_message        = each.value.merge_commit_message
  squash_merge_commit_title   = each.value.squash_merge_commit_title
  squash_merge_commit_message = each.value.squash_merge_commit_message
  topics                      = each.value.topics

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      has_downloads,
      ignore_vulnerability_alerts_during_read,
    ]
  }
}

resource "github_actions_repository_permissions" "repositories" {
  for_each = local.repositories

  repository      = github_repository.repositories[each.key].name
  enabled         = each.value.actions_enabled
  allowed_actions = each.value.actions_allowed
}

resource "github_workflow_repository_permissions" "repositories" {
  for_each = local.repositories

  repository                       = github_repository.repositories[each.key].name
  default_workflow_permissions     = each.value.workflow_permission
  can_approve_pull_request_reviews = each.value.can_approve_pull_requests
}

resource "github_repository_environment" "environments" {
  for_each = local.environments

  repository          = github_repository.repositories[each.value.repository].name
  environment         = each.value.environment
  can_admins_bypass   = each.value.can_admins_bypass
  prevent_self_review = each.value.prevent_self_review
}

resource "github_repository_deploy_key" "flux" {
  for_each = local.flux_deploy_keys

  repository = github_repository.repositories[each.value.repository].name
  title      = each.value.title
  key        = each.value.key
  read_only  = each.value.read_only

  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "dotfiles_main" {
  repository_id           = github_repository.repositories["dotfiles"].node_id
  pattern                 = "main"
  allows_deletions        = false
  allows_force_pushes     = false
  enforce_admins          = false
  require_signed_commits  = false
  required_linear_history = false
  lock_branch             = false
}
