terraform {
  required_version = ">= 1.8.0"

  required_providers {
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.18"
    }
  }

  backend "s3" {
    bucket = "luck-dotfiles-opentofu-state"
    key    = "homelab/tailscale/tailnet/terraform.tfstate"
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
  }
}
