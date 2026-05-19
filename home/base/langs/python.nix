{pkgs, ...}: {
  home.packages = with pkgs; [
    python313
  ];

  # https://mynixos.com/home-manager/options/programs.uv
  programs.uv = {
    enable = true;

    # https://docs.astral.sh/uv/reference/settings/
    settings = {
      # 只允许解析 7 天前发布的包，降低刚发布恶意版本被立即安装的风险
      exclude-newer = "7 days";
      python-downloads = "never";
      python-preference = "system";
    };
  };

  # Python 相关环境变量
  #  home.sessionVariables = {
  #    # UV 缓存目录
  #    UV_CACHE_DIR = "$HOME/.cache/uv";
  #    # UV 配置目录
  #    UV_CONFIG_FILE = "$HOME/.config/uv/uv.toml";
  #    # Python 路径
  #    PYTHONPATH = "$HOME/.local/lib/python3.13/site-packages:$PYTHONPATH";
  #  };

  # 添加有用的 UV 别名
  programs.zsh.shellAliases = {
    #    # 快速安装包
    #    uvi = "uv add";
    #    # 移除包
    #    uvr = "uv remove";
    #    # 列出已安装的包
    #    uvl = "uv pip list";
    #    # 显示包信息
    #    uvs = "uv pip show";
    #    # 运行 Python 脚本
    #    uvrun = "uv run";
    #    # 同步依赖
    #    uvsync = "uv sync";
    #    # 锁定依赖
    #    uvlock = "uv lock";
  };
}
