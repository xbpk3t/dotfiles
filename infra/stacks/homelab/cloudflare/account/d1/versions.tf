terraform {
  required_version = ">= 1.8.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  # Cloudflare account-scoped stacks 统一落到 Cloudflare R2 remote backend。
  # 这样这条线后续可以独立维护，不再依赖旧的 MinIO backend。
  backend "s3" {
    bucket = "luck-dotfiles-opentofu-state"
    key    = "homelab/cloudflare/account/d1/terraform.tfstate"
    region = "auto"

    endpoints = {
      s3 = "https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com"
    }

    # 通过 env 提供 R2 S3-compatible backend 凭据。
    # 不要把 access key / secret key 直接写入仓库。
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
