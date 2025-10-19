{pkgs, config, ...}: {
  home.packages = with pkgs; [
    go

    gotools # goimports
    gum
    gofumpt
    golangci-lint
    gosec
    protoc-gen-go
    protoc-gen-go-grpc
    gopls # https://github.com/golang/tools includes modernize
    golines # https://github.com/segmentio/golines
    goimports-reviser
    cobra-cli
    nilaway
    go-swag # = swaggo/swag
    goreleaser
    go-mockery # https://github.com/vektra/mockery
    templ # https://github.com/a-h/templ
    go-migrate # https://github.com/golang-migrate/migrate
  ];

  # Go 运行时和配置
  programs.go = {
    enable = true;

    package = pkgs.go;

    # Go 环境变量设置 (更新为新语法)
    env = {
      # GOROOT 设置 - 确保与 go 版本一致
      # 否则会出现 go env GOROOT 和 go version 显示 golang version 不一致的情况
      GOROOT = "${pkgs.go}/share/go";

      # GOPATH 设置
      GOPATH = "${config.home.homeDirectory}/go";

      # GOPROXY 设置
      GOPRIVATE = "*.corp.example.com,rsc.io/private"; # 私有模块设置

      # Go 代理设置（中国镜像）
      GOPROXY = "https://goproxy.cn,direct";
      GOSUMDB = "sum.golang.google.cn";

      GOMODCACHE = "${config.home.homeDirectory}/go/pkg/mod";

      # Go 模块设置
      GO111MODULE = "on";

      # CGO 设置
      CGO_ENABLED = "0";
    };
  };
}
