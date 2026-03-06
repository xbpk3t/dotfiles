{
  pkgs,
  config,
  ...
}: {
  # home.packages = with pkgs; [
  #   # https://mynixos.com/nixpkgs/package/baidupcs-go
  #   # https://github.com/qjfoidnh/BaiduPCS-Go
  #   # [2025-11-13] 临时使用后注释掉。还是很好用的。
  #   baidupcs-go
  # ];

  # https://mynixos.com/home-manager/options/programs.rclone
  #
  # [2026-01-25] 发现darwin上并没有生成 rclone.conf，查了一下才发现rclone的conf文件是要用systemd来生成的，而明显darwin上就无法生成了（之前用的restic, kopia之类的hm同样有类似问题）。自己写了一下darwin的 home.activation 来生成这个conf，又发现代码并不简洁，所以又删掉了。
  #
  #
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/rclone.nix#L19
  #
  # https://mynixos.com/home-manager/option/programs.rclone.remotes.%3Cname%3E.secrets
  #
  #
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
          access_key_id = config.sops.secrets.cf_r2_AK.path;
          secret_access_key = config.sops.secrets.cf_r2_SK.path;
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
