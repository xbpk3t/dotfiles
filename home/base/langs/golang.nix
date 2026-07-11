{
  pkgs,
  config,
  ...
}:
{
  home.packages =
    with pkgs;
    [
      # 分类1：Go 核心工具链与语言服务
      go
      gotools
      # (lib.lowPrio gopls)
    ]
    ++ [
      # 分类2：代码质量与静态分析
      # [2026-04-20] 注释掉 gosec, gofumpt, golines，因为本身可以作为 golangci-lint 的 linters/formatters 使用
      # tags(desc): 代码质量 > 聚合检查 > 静态分析
      golangci-lint
      golangci-lint-langserver

      # tags(desc): 代码质量 > import规范化 > 格式化
      goimports-reviser

      # tags(desc): 代码质量 > 静态分析 > 空指针安全
      nilaway

      # tags(desc): 代码质量 > 可读性 > 对齐格式化
      betteralign
    ]
    ++ [
      # 分类3：代码生成与工程脚手架
      # tags(desc): 代码生成 > Protobuf > 序列化
      protoc-gen-go


      # tags(desc): 测试工具 > Mock生成 > 代码生成
      go-mockery

      # tags(desc): 前端模板 > 代码生成 > Go生态
      templ

      # tags(desc): 工程脚手架 > 微服务框架 > 代码生成
      goctl
    ]
    ++ [
      # 分类4：发布、迁移与依赖分析
      go-migrate
      go-mod-graph-chart
    ]
    ++ [
      # Test
      tparse
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
