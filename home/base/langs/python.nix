{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.langs.python;
in
{
  options.modules.langs.python.enable = lib.mkEnableOption "Python (python313 / uv)";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.python313 ];

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

  };
}
