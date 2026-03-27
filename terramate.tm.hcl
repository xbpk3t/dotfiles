terramate {
  required_version = ">= 0.10.0"

  config {
    git {
      default_branch = "main"
    }
  }
}

globals {
  project_name = "dotfiles-infra"
}
