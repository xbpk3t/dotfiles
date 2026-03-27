terraform {
  required_version = ">= 1.8.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "luck-dotfiles-opentofu-state"
    key    = "homelab/cloudflare/lucc.dev/email-routing/terraform.tfstate"
    region = "auto"

    endpoints = {
      s3 = "https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com"
    }

    # Email Routing 和 DNS 分开 state。
    # Why: DNS 变更频率和邮件规则变更频率不一致，分开更安全。
    #
    # backend 凭据仍然通过 env 注入，只是这里接的是 Cloudflare R2，而不是 AWS S3。
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
