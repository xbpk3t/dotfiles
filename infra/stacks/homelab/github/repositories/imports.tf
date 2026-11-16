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
