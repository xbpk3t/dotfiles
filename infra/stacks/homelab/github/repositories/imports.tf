import {
  for_each = local.repositories

  to = github_repository.repositories[each.key]
  id = each.value.name
}

import {
  for_each = local.repositories

  to = github_actions_repository_permissions.repositories[each.key]
  id = each.value.name
}

import {
  for_each = local.repositories

  to = github_workflow_repository_permissions.repositories[each.key]
  id = each.value.name
}

import {
  for_each = local.environments

  to = github_repository_environment.environments[each.key]
  id = "${each.value.repository}:${each.value.environment}"
}

import {
  for_each = local.flux_deploy_keys

  to = github_repository_deploy_key.flux[each.key]
  id = "${each.value.repository}:${each.value.id}"
}
