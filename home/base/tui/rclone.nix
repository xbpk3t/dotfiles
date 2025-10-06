{pkgs, ...}: {
  programs.rclone = {
    enable = true;
    package = pkgs.rclone; # 可选：覆盖默认包

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
          access_key_id = "/etc/sk/rclone/r2/access_key_id";
          secret_access_key = "/etc/sk/rclone/r2/secret_access_key";
        };
      };
    };

    # 暂时移除 sops-nix 依赖，避免服务启动失败
    # requiresUnit = "sops-nix.service";
  };
}
