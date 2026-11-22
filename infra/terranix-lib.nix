# terranix stack 的共享 Terraform 骨架。
#
# 只收敛机械重复的 required_version / required_providers / R2 backend；
# 资源、import、moved 等 stack 语义仍留在各自的 terranix.nix。
{
  mkTerraform =
    {
      stateKey,
      r2Endpoint,
      providers,
      requiredVersion ? ">= 1.10.0",
      bucket ? "luck-dotfiles-opentofu-state",
    }:
    {
      required_version = requiredVersion;

      required_providers = providers;

      backend.s3 = {
        inherit bucket;
        key = stateKey;
        region = "auto";

        endpoints.s3 = r2Endpoint;

        # 通过 env 提供 R2 S3-compatible backend 凭据；不要写进仓库。
        skip_credentials_validation = true;
        skip_metadata_api_check = true;
        skip_region_validation = true;
        skip_requesting_account_id = true;
        skip_s3_checksum = true;
        use_path_style = true;

        # R2 支持 S3 条件写；用原生 lockfile 替代 DynamoDB 锁表。
        use_lockfile = true;
      };
    };
}
