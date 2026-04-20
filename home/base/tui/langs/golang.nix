{
  pkgs,
  config,
  ...
}: {
  home.packages = with pkgs; [
    go

    # goimports
    # https://mynixos.com/nixpkgs/package/gotools
    gotools

    gum

    # [2026-04-20] 注释掉 gosec, gofumpt, golines，因为本身可以作为 golangci-lint 的 linters/formatters 使用
    golangci-lint
    # https://mynixos.com/nixpkgs/package/gosec
    # https://github.com/securego/gosec
    # gosec
    # gofumpt
    # https://github.com/segmentio/golines
    # golines

    protoc-gen-go
    protoc-gen-go-grpc
    # https://github.com/golang/tools includes modernize
    gopls

    goimports-reviser
    cobra-cli
    nilaway

    # = swaggo/swag
    go-swag
    goreleaser

    # https://github.com/vektra/mockery
    go-mockery

    # https://github.com/a-h/templ
    templ

    # https://github.com/golang-migrate/migrate
    go-migrate

    # https://mynixos.com/nixpkgs/package/go-mod-graph-chart
    go-mod-graph-chart

    # https://mynixos.com/nixpkgs/package/goctl
    goctl

    # https://mynixos.com/nixpkgs/package/betteralign
    betteralign
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
