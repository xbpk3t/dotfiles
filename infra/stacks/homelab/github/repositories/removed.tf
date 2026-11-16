# Flux deploy keys were tied to the manifests/flux GitRepository and are no
# longer needed after the k3s/manifests removal. `destroy = true` keeps the
# next apply responsible for deleting the two old keys from GitHub.
removed {
  from = github_repository_deploy_key.flux

  lifecycle {
    destroy = true
  }
}
