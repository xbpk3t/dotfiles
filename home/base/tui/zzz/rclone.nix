{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/baidupcs-go
    # https://github.com/qjfoidnh/BaiduPCS-Go
    # [2025-11-13] 临时使用后注释掉。还是很好用的。
    baidupcs-go
  ];

  # https://mynixos.com/home-manager/options/programs.rclone
  programs.rclone = {
    enable = true;
    package = pkgs.rclone;

    remotes = {
      r2 = {
        config = {
          type = "s3";
          provider = "Cloudflare";
          env_auth = "true";
          region = "auto";
          endpoint = "https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com";
          acl = "private";
        };
        secrets = {
          access_key_id = config.sops.secrets.rcloneR2AccessKeyId.path;
          secret_access_key = config.sops.secrets.rcloneR2SecretAccessKey.path;
        };
      };

      #      oss = {
      #        config = {
      #
      #        };
      #        secrets = {
      #
      #        };
      #      };
    };

    # 暂时移除 sops-nix 依赖，避免服务启动失败
    # requiresUnit = "sops-nix.service";
  };
}
