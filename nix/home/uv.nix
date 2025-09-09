{ ... }:

{
  programs.uv = {
    enable = true;

    # UV 配置
    settings = {
      # 全局设置
      global = {
        # 使用中国镜像源以提高下载速度
        index-url = "https://pypi.tuna.tsinghua.edu.cn/simple";
        # 额外索引 URL
        extra-index-url = [
          "https://pypi.org/simple"
        ];
        # 信任的主机
        trusted-host = [
          "pypi.tuna.tsinghua.edu.cn"
        ];
      };

      # 缓存设置
      cache = {
        # 缓存目录（默认为 ~/.cache/uv）
        # dir = "$HOME/.cache/uv";
      };

      # 网络设置
      network = {
        # 并发下载数
        concurrent-downloads = 4;
        # 超时设置
        timeout = 30;
      };
    };
  };

  # Python 相关环境变量
  home.sessionVariables = {
    # UV 缓存目录
    UV_CACHE_DIR = "$HOME/.cache/uv";
    # UV 配置目录
    UV_CONFIG_FILE = "$HOME/.config/uv/uv.toml";
    # Python 路径
    PYTHONPATH = "$HOME/.local/lib/python3.13/site-packages:$PYTHONPATH";
  };

  # 添加有用的 UV 别名
  programs.zsh.shellAliases = {
    # 快速安装包
    uvi = "uv add";
    # 移除包
    uvr = "uv remove";
    # 列出已安装的包
    uvl = "uv pip list";
    # 显示包信息
    uvs = "uv pip show";
    # 运行 Python 脚本
    uvrun = "uv run";
    # 同步依赖
    uvsync = "uv sync";
    # 锁定依赖
    uvlock = "uv lock";
  };
}
