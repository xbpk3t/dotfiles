{
  # ==================================================================
  #
  # Tool for creating snapshots and remote backups of btrfs subvolumes
  #   https://github.com/digint/btrbk
  #
  # Usage:
  #   1. btrbk will create snapshots on schedule
  #   2. we can use `btrbk run` command to create a backup manually
  #
  # How to restore a snapshot:
  #   1. Find the snapshot you want to restore in /snapshots
  #   2. Use `btrfs subvol delete /btr_pool/@persistent` to delete the current subvolume
  #   3. Use `btrfs subvol snapshot /snapshots/2021-01-01 /btr_pool/@persistent` to restore the snapshot
  #   4. reboot the system or remount the filesystem to see the changes
  #
  # ==================================================================

  # NOTE
  # 仅 btrfs 且需要快照/备份的主机才用，适合放到 homelab 或 server-backup profile，下沉出 base。

  # - 开启一个名为 btrbk 的 btrbk 实例，按 onCalendar = "Tue,Sat 03:45:20" 运行。
  # - 对卷 /btr_pool 的子卷 @persistent 生成 btrfs 快照（snapshot_create =
  #   "always"），并用保留策略：
  #     - 本地快照：最少 2 天，常规保留 7 天。
  #     - 远端/目标保留策略已写（9 天日备、4 周周备、2 个月月备），但 target 被注
  #       释掉，当前不会复制到远端。
  # - 没有启用 target 时，效果只是定期在本机创建/修剪快照；不存在复制。

  # 是否需要启用/保留，取决于：

  # 1. 你的根或数据卷是否是 btrfs，且路径 /btr_pool/@persistent 是否存在并需要定
  #    期快照/备份。
  # 2. 是否希望“无人值守快照 + 可选远端增量备份”这一特性；如果已有别的备份方案
  #    （如 snapper、sanoid、restic + systemd timers），可以移除。
  # 3. 如果卷、子卷名不同，或用 LUKS/ZFS/ext4，则此模块会报错或无效，应删掉或改成
  #    匹配的路径。
  # 4. 需要异地备份时，取消注释 target = ...（如 SSH/本地目录），并保证目标路径
  #    可写。

  # 简判：

  # - 用 btrfs，想要定期快照/未来可能远端复制 → 保留并改成你的卷/子卷/目标。
  # - 不用 btrfs 或已有替代备份 → 可以删除该模块。

  services.btrbk.instances.btrbk = {
    # How often this btrbk instance is started. See systemd.time(7) for more information about the format.
    onCalendar = "Tue,Sat *-*-* 3:45:20";
    settings = {
      # how to prune local snapshots:
      # 1. keep daily snapshots for xx days
      snapshot_preserve = "7d";
      # 2. keep all snapshots for 2 days, no matter how frequently you (or your cron job) run btrbk
      snapshot_preserve_min = "2d";

      # hot to prune remote incremental baqckups:
      # keep daily backups for 9 days, weekly backups for 4 weeks, and monthly backups for 2 months
      target_preserve = "9d 4w 2m";
      target_preserve_min = "no";

      volume = {
        "/btr_pool" = {
          subvolume = {
            "@persistent" = {
              snapshot_create = "always";
            };
          };

          # backup to a remote server or a local directory
          # its prune policy is defined by `target_preserve` and `target_preserve_min`
          # target = "/snapshots";
        };
      };
    };
  };
}
