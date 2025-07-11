{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 版本控制
    # git - 由 home-manager 管理
    gh
    git-lfs
    git-quick-stats
    gitleaks
    gitlint
    bfg-repo-cleaner

    # 容器和虚拟化
    docker
    docker-compose
    docker-credential-helpers
    # colima

    # Kubernetes 工具
    # helm - 在macOS上不可用，由 home-manager 管理
    # helmfile
    # kompose
    # kube-linter
    kubectx
    # minikube  # 可能导致qemu依赖，暂时移除

    # 构建和任务工具
    go-task
    dotbot
    pre-commit
    # talisman  # 包不存在
    # mockery   # 包不存在

    # 代码质量和分析
    # cloc
#    hadolint
#    shellcheck
#    yamllint
#    markdownlint-cli
#    lychee

    # 环境管理
    # direnv

    # 数据库工具
    # mysql80  # 大型依赖，暂时移除
    # pgloader

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
