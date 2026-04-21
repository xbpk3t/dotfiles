_: {
  # - 含义：全局白名单，告诉 Mole 这些路径不要动（避免被 clean/optimize/purge误清，具体以命令实现为准）。
  # - 用途：保护“非纯缓存、重建成本高或有数据风险”的目录，比如浏览器用户数据、iOS 本地备份、密钥目录等。
  home.file.".config/mole/whitelist".text = ''
    ~/.cache/pre-commit
  '';

  # - 含义：只给 mo purge 用的扫描范围列表。
  # - 用途：把 purge 限定在你指定的项目根目录下跑；配置后不会再按默认目录全盘找。
  #  home.file.".config/mole/purge_paths".text = ''
  #  '';

  home.shellAliases = {
    "moc" = "mo clean --dry-run --debug";
    "mop" = "mo purge --dry-run";
    "mos" = "mo status";
  };
}
