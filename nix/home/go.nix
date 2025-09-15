{...}: {
  programs.go = {
    enable = true;

    # Go 版本将使用系统包中的版本
    # package = pkgs.go; # 可以显式指定版本

    # Go 环境变量设置 (更新为新语法)
    env = {
      # GOPATH 设置
      GOPATH = "go"; # 相对于 home 目录，即 ~/go

      # GOPROXY 设置
      GOPRIVATE = "*.corp.example.com,rsc.io/private"; # 私有模块设置

      # Go 代理设置（中国镜像）
      GOPROXY = "https://goproxy.cn,direct";
      GOSUMDB = "sum.golang.google.cn";

      # Go 模块设置
      GO111MODULE = "on";

      # CGO 设置
      CGO_ENABLED = "0";
    };
  };
}
