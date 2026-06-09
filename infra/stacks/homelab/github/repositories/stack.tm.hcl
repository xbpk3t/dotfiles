stack {
  name        = "github-repositories"
  description = "GitHub repository governance baseline for core personal repositories."
  tags = [
    "layer-infra",
    "env-homelab",
    "github",
    "repositories",
  ]
}

globals {
  terraform_root = "."
  state_id       = "homelab/github/repositories"
}
