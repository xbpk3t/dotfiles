{ pkgs, ... }:

{
  programs.rclone = {
    enable = true;
    package = pkgs.rclone;  # 可选：覆盖默认包

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
          access_key_id = "/etc/rclone/r2/access_key_id";
          secret_access_key = "/etc/rclone/r2/secret_access_key";
        };
      };
    };

    # 控制配置文件写入时机 - 在 sops 解密后写入
    writeAfter = "postactivation";
  };
}
