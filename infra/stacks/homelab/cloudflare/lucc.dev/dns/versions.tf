terraform {
  required_version = ">= 1.8.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }

  # Cloudflare stacks 改为落到 Cloudflare R2 remote backend。
  # 这样日常维护不再依赖旧的 MinIO / AWS_* 凭据链路。
  #
  # 注意：
  # 1. backend bucket 本身属于 bootstrap resource，不由当前 stack 首次创建
  # 2. sensitive 的 access key / secret key 通过 env 注入，不写入仓库
  backend "s3" {
    bucket = "luck-dotfiles-opentofu-state"
    key    = "homelab/cloudflare/lucc.dev/dns/terraform.tfstate"
    region = "auto"

    endpoints = {
      s3 = "https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com"
    }

    # Cloudflare R2 走 S3-compatible API，需要关闭一部分 AWS 专属校验。
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
  }
}
