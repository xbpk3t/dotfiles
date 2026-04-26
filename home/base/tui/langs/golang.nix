{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      # 分类1：Go 核心工具链与语言服务
      # tags(desc): 核心工具链 > 语言运行时 > Go
      go

      # goimports
      # https://mynixos.com/nixpkgs/package/gotools
      # tags(desc): 核心工具链 > 官方工具集 > Go
      gotools

      # https://github.com/golang/tools includes modernize
      # tags(desc): 语言服务 > LSP > 代码智能
      # [2026-04-26] 跟 gotools 的 modernize pkg conflicts 了
      (lib.lowPrio gopls)

      # tags(desc): 开发体验 > 交互CLI > 终端UI
      gum
    ]
    ++ [
      # 分类2：代码质量与静态分析
      # [2026-04-20] 注释掉 gosec, gofumpt, golines，因为本身可以作为 golangci-lint 的 linters/formatters 使用
      # tags(desc): 代码质量 > 聚合检查 > 静态分析
      golangci-lint
      # https://mynixos.com/nixpkgs/package/gosec
      # https://github.com/securego/gosec
      # gosec
      # gofumpt
      # https://github.com/segmentio/golines
      # golines

      # tags(desc): 代码质量 > import规范化 > 格式化
      goimports-reviser

      # tags(desc): 代码质量 > 静态分析 > 空指针安全
      nilaway

      # https://mynixos.com/nixpkgs/package/betteralign
      # tags(desc): 代码质量 > 可读性 > 对齐格式化
      betteralign
    ]
    ++ [
      # 分类3：代码生成与工程脚手架
      # tags(desc): 代码生成 > Protobuf > 序列化
      protoc-gen-go

      # tags(desc): 代码生成 > gRPC > Protobuf
      protoc-gen-go-grpc

      # tags(desc): 工程脚手架 > CLI框架 > 代码生成
      cobra-cli

      # = swaggo/swag
      # tags(desc): 代码生成 > API文档 > OpenAPI
      go-swag

      # https://github.com/vektra/mockery
      # tags(desc): 测试工具 > Mock生成 > 代码生成
      go-mockery

      # https://github.com/a-h/templ
      # tags(desc): 前端模板 > 代码生成 > Go生态
      templ

      # https://mynixos.com/nixpkgs/package/goctl
      # tags(desc): 工程脚手架 > 微服务框架 > 代码生成
      goctl
    ]
    ++ [
      # 分类4：发布、迁移与依赖分析
      # tags(desc): 发布交付 > Release自动化 > CI/CD
      goreleaser

      # https://github.com/golang-migrate/migrate
      # tags(desc): 数据迁移 > 数据库 > 运维
      go-migrate

      # https://mynixos.com/nixpkgs/package/go-mod-graph-chart
      # tags(desc): 依赖分析 > 可视化 > 模块管理
      go-mod-graph-chart
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
