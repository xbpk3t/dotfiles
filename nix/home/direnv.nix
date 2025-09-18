_: {
  programs.direnv = {
    enable = false;
    # 启用 nix-direnv 集成以提高性能
    nix-direnv.enable = false;

    # 自动允许 .envrc 文件（可选，安全考虑建议设为 false）
    # stdlib = ''
    #   # 自定义 stdlib 配置
    # '';

    config = {
      # 全局配置
      global = {
        # 禁用提示，避免干扰
        warn_timeout = "24h";
        # 设置缓存目录
        # cache_dir = "$HOME/.cache/direnv";
      };
    };
  };
}
