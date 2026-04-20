{config, ...}: {
  # https://mynixos.com/nixpkgs/options/services.journald
  # journald / journalctl 日志策略
  services.journald = {
    # 持久化保存日志，重启后仍可查询
    storage = "persistent";

    # 不主动开启也不主动关闭内核 audit，保持当前系统状态
    # 这是最稳妥的选择，基本不会和 auditd 之类的组件打架
    audit = "keep";

    # 不转发到控制台
    # 留空表示关闭；生产环境一般不建议开控制台转发
    console = "";

    # 仅当系统里启用了 rsyslog / syslog-ng 时才转发到 syslog
    # 这样最接近 NixOS 默认行为，也最不容易误伤现有日志链路
    forwardToSyslog =
      config.services.rsyslogd.enable
      || config.services.syslog-ng.enable;

    # 每个 service 单独做速率限制
    # 30 秒一个窗口
    rateLimitInterval = "30s";

    # 单个 service 在一个窗口内最多 10000 条
    # 超出后 journald 会丢弃后续消息，并记录 dropped 提示
    rateLimitBurst = 10000;

    # 真正决定“自动清到什么程度”的，是 journald.conf 里的保留策略，比如 SystemMaxUse=、RuntimeMaxUse=、SystemKeepFree=、RuntimeKeepFree=、SystemMaxFileSize=、SystemMaxFiles=。这些限制默认就有值：最大使用量默认按文件系统大小的 10% 计算，保留空闲空间默认按 15% 计算，并且各自默认值都封顶到 4G；单个日志文件大小默认大约是总上限的 1/8，通常会保留大约 7 个轮转历史文件。也就是说，默认不是无限增长。
    extraConfig = ''
      # 启用压缩
      # systemd 默认就是 yes；显式写出来便于以后排查
      Compress=yes

      # 启用 Forward Secure Sealing
      # 只有你执行过 `journalctl --setup-keys` 且存在 sealing key 时才真正生效
      # 没有 key 也不会出问题
      Seal=yes

      # 持久化日志按用户拆分文件，便于权限隔离
      # persistent 模式下默认就是 uid；显式写出来只是为了可读性
      SplitMode=uid

      # journal 最多吃 1G 持久化空间
      SystemMaxUse=1G

      # 至少给文件系统留 512M 空闲
      SystemKeepFree=512M

      # 单个 journal 文件最大 128M
      # 对 1G 总上限来说比较均衡，也便于更细粒度轮转
      # 事实上这也和 systemd 在这个上限下的默认推导值一致
      SystemMaxFileSize=128M

      # 单个 journal 文件最长保留 1 天后轮转
      # 这项不是必须；如果你想更贴近默认行为，可以删掉这行
      # 默认通常是 1 个月，官方也说明多数场景下光靠 size-based rotation 就够了
      MaxFileSec=1day

      # 最多保留 14 天历史日志
      # 默认 0 表示不按时间删，只按空间策略删
      MaxRetentionSec=14day

      # 低优先级日志最多延迟 5 分钟刷盘
      # 这是 systemd 默认值，显式写出来便于理解和排查
      SyncIntervalSec=5m

      # 允许 stdout/stderr 的单行日志最长 48K
      # 这是 systemd 默认值，显式写出来只是为了可读性
      LineMax=48K

      # 接收内核 /dev/kmsg 日志
      # 默认 namespace 下默认就是 yes；显式写出来便于确认行为
      ReadKMsg=yes
    '';
  };
}
