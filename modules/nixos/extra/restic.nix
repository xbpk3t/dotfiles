{
  config,
  myvars,
  ...
}: {
  # https://mynixos.com/nixpkgs/options/services.restic
  # 仅在 NixOS 端定时备份 docs-images 到 Cloudflare R2

  # https://raw.githubusercontent.com/notthebee/nix-config/refs/heads/main/modules/homelab/backup/default.nix

  services.restic.backups."docs-images" = {
    initialize = true;

    # Cloudflare R2（S3 兼容）仓库
    repository = "s3:https://96540bd100b82adba941163704660c31.r2.cloudflarestorage.com/docs";

    # restic 仓库密码（从 sops-nix 读取）
    passwordFile = config.sops.secrets.pwgenSk.path;

    # 备份路径（只关心 docs-images）
    paths = ["/home/${myvars.username}/Desktop/docs-images"];

    # 排除规则：如需额外忽略，可在此追加
    exclude = ["**/.cache" "*.tmp" "*.swp" "*.swx"];

    # 保留策略：7 天日快照、4 周周快照、6 个月月快照
    pruneOpts = ["--keep-daily" "7" "--keep-weekly" "4" "--keep-monthly" "6"];

    # 定时：每日运行，掉电/关机期间的任务下次补跑
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };

    runCheck = true;

    # 通过 ExecStartPre 生成临时 env 文件，把 R2 凭据喂给 restic
    environmentFile = "/run/restic/docs-images.env";

    backupPrepareCommand = ''
            set -euo pipefail
            install -d -m 0700 -o root -g root /run/restic
            cat > /run/restic/docs-images.env <<EOF
      AWS_ACCESS_KEY_ID=$(cat ${config.sops.secrets.rcloneR2AccessKeyId.path})
      AWS_SECRET_ACCESS_KEY=$(cat ${config.sops.secrets.rcloneR2SecretAccessKey.path})
      AWS_DEFAULT_REGION=auto
      EOF
            chmod 0400 /run/restic/docs-images.env
    '';

    backupCleanupCommand = ''
      rm -f /run/restic/docs-images.env
    '';
  };
}
