{ ... }:

{
  programs.direnv = {
    enable = true;
    # 启用 nix-direnv 集成以提高性能
    nix-direnv.enable = true;

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

  # 添加 shell 集成
  # programs.zsh.initContent = ''
  #   # direnv 已经通过 programs.direnv 自动集成到 zsh
  # '';
}
