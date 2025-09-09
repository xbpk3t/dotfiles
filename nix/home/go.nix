{ ... }:

{
  programs.go = {
    enable = true;

    # Go 版本将使用系统包中的版本
    # package = pkgs.go; # 可以显式指定版本

    # GOPATH 设置
    goPath = "go";  # 相对于 home 目录，即 ~/go

    # GOPROXY 设置
    goPrivate = [ "*.corp.example.com" "rsc.io/private" ]; # 私有模块设置
  };

  # 在 shell 中设置额外的 Go 相关环境变量
  home.sessionVariables = {
    # Go 代理设置（中国镜像）
    GOPROXY = "https://goproxy.cn,direct";
    GOSUMDB = "sum.golang.google.cn";

    # Go 模块设置
    GO111MODULE = "on";

    # CGO 设置
    CGO_ENABLED = "0";
  };
}
