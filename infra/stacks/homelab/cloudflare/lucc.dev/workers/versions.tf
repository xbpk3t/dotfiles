terraform {
  required_version = ">= 1.10.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "luck-dotfiles-opentofu-state"
    key    = "homelab/cloudflare/lucc.dev/workers/terraform.tfstate"
    region = "auto"

    endpoints = {
      s3 = "https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com"
    }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    use_lockfile                = true
  }
}
