{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 构建和任务工具
    go-task
    dotbot
    pre-commit
    # talisman  # 包不存在
    # mockery   # 包不存在

    # 代码质量和分析
    # cloc
    # hadolint
    # shellcheck
    # yamllint
    # markdownlint-cli
    # lychee

    # 环境管理
    # direnv

    # API 工具
    # grpcurl
    # httpie

    # 其他开发工具
    # graphviz
    # pandoc
    # carthage   # 包不存在
    # cabextract # 包不存在
  ];
}
