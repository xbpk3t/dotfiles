{
  username,
  inputs ? {},
  pkgs,
  lib,
  ...
}: let
  db = with pkgs; [
    # 数据库工具
    # mysql80  # 大型依赖，暂时移除
    # pgloader

    # mysql-client # https://mynixos.com/nixpkgs/package/mysql-client
    # postgresql # https://mynixos.com/nixpkgs/package/postgresql
  ];

  devops = with pkgs; [
    # 构建和任务工具
    go-task
    dotbot
    pre-commit

    # CICD
    # ansible  # Temporarily disabled due to hash mismatch in ncclient dependency
    opentofu
    cf-terraforming

    # 代码质量和分析
    shellcheck
    yamllint
    markdownlint-cli

    urlscan
    lychee

    cloudflared # cloudflare tunnel

    # wrangler # https://github.com/cloudflare/workers-sdk

    # API 工具
    grpcurl

    # 基础工具
    coreutils
    findutils
    diffutils
    gawk
    gnused
    gnutar
    gzip

    # 其他实用工具
    watch
    rsync
    cowsay

    # 证书和密钥管理
    openssl

    # 基础媒体处理
    ffmpeg

    # 音频处理
    # sox
    # lame

    # 图像处理
    imagemagick
    exiftool
    graphviz
  ];

  kernel = with pkgs; [
    # 网络工具 (excluding wget/curl which are in minimal)
    mosh
    fping
    nmap
    inetutils
    mtr
    nexttrace # 可视化路由跟踪工具

    # disk
    ncdu

    # 网络安全
    subfinder # https://github.com/projectdiscovery/subfinder 【子域名发现工具，支持多个数据源和被动枚举】它已成为sublist3r项目的继承者。SubFinder使用被动源，搜索引擎，Pastebins，Internet Archives等来查找子域，然后使用灵感来自于altdns的置换模块来生成排列，并使用强大的bruteforcing引擎快速的解析它们。如果需要，它也可以执行纯粹的爆破。此外，SubFinder还具有高可定制性。其代码构建模块化的特点，使你能够轻松地添加功能或移除错误。
    naabu # https://github.com/projectdiscovery/naabu 端口扫描工具

    # rename
    rnr # https://github.com/ismaelgv/rnr # FIXME 添加rnr的taskfile
  ];

  langs = with pkgs; [
    # Python
    python313

    # Rust
    rustup

    # 其他语言
    # php
    # elixir
    # android-tools

    lua
  ];

  ts = with pkgs; [
    # Node.js 生态
    nodejs
    nodePackages.eslint
    nodePackages.pnpm
    nodePackages.serve # https://github.com/vercel/serve 用来preview本地打包好的dist文件（vite可以直接vite preview）
    tsx

    # Web 开发
    tailwindcss
    tailwindcss-language-server

    npm-check # https://github.com/dylang/npm-check 可以认为 npm-check = depcheck + npm-check-updates. 可以用来检查并自动更新dependency，也支持检查unused依赖项. Check for outdated, incorrect, and unused dependencies in package.json.
    npm-check-updates # https://github.com/raineorshine/npm-check-updates 顾名思义，相当于 `npm-check -u`，用来检查pkg版本是否有新版本. 支持brew安装。`ncu -u`
  ];

  k8s = with pkgs; [
    # Docker
    hadolint

    # Kubernetes 工具
    minikube
    # helm # helm在macos上不支持用nix安装
    # helmfile
    kompose
    kube-linter # https://github.com/stackrox/kube-linter

    kubectx # https://github.com/ahmetb/kubectx 用来快速切换context
    kubie # https://github.com/sbstp/kubie
    kubectl
    kubefwd # https://github.com/txn2/kubefwd
    kube-capacity # https://github.com/robscott/kube-capacity 颇为实用的工具。k8s的命令行工具kubectl用来查看集群的整体资源情况往往操作会比较复杂，可能需要多条命令配合在一起才能拿得到想要的结果。kube-capacity命令行工具用来快速查看集群中的资源使用情况，包括node、pod维度。

    kubernetes-polaris
    conftest
    kty # https://github.com/grampelberg/kty
    kubectl-graph # https://github.com/steveteuber/kubectl-graph  最近接手了一个规模比较大的集群，光是整理集群中的资源就使人头昏眼花，虽然我自认 kubectl 使用的已经十分熟练，但是上千个 k8s Resource 看下来还是不堪重负。在不能为集群安装任何其他工具的情况下，可以改造的就只有我自己的 Client 端，也就是 kubectl 了。本文就介绍一个有趣的 kubectl 插件：kubectl-graph。

    cilium-cli # https://github.com/cilium/cilium-cli
    #  一键安装 Cilium：自动检测集群类型（如 minikube、GKE、EKS）并适配配置。
    #  集群诊断：运行连接性测试（cilium connectivity test）、查看状态（cilium status）。
    #  高级功能管理：启用 Hubble（网络流量可视化）、ClusterM esh（多集群互联）、IPsec 加密等。
    #  版本管理：支持安装/升级到指定 Cilium 版本。

    kubebuilder
    kubecm # 该项目脱胎于 mergeKubeConfig 项目，最早写该项目的目的是在一堆杂乱无章的 kubeconfig 中自由的切换。随着需要操作的 k8s 集群越来越多，在不同的集群之间切换也越来越麻烦，而操作 k8s 集群的本质不过是通过 kubeconfig 访问 k8s 集群的 API Server，以操作 k8s 的各种资源，而 kubeconfig 不过是一个 YAML 文件，用来保存访问集群的密钥，最早的 mergeKubeConfig 不过是一个操作 YAML 文件的 Python 脚本。而随着 Go 学习的深入，也就动了重写这个项目的念头，就这样 kubecm 诞生了。
  ];

  test = with pkgs; [
    k6
    # vegeta
    # speedtest-cli
  ];

  markdown = with pkgs; [
    python313Packages.markitdown # https://github.com/microsoft/markitdown 把 microsoft office文档转成md
    docling # https://github.com/DS4SD/docling Easy Scraper是不是就使用这个实现的？支持读取多种流行的文档格式（PDF、DOCX、PPTX、图像、HTML 等）并出为 Markdown 和 JSON。具备先进的 PDF 理解能力，包括页面布局、阅读顺序及表格结构。提供统一且表达丰富 DoclingDocument 表示格式。能够提取元数据，如标题、作者及语言等信息。
    mdq # https://github.com/yshavit/mdq like jq but for Markdown, find specific elements in a md doc
  ];

  sec = with pkgs; [
    katana
  ];

  all = db ++ devops ++ kernel ++ langs ++ ts ++ k8s ++ test ++ markdown ++ sec;
in {
  home.packages = all;
  # import sub modules
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./bash.nix
    ./git.nix
    ./neovim.nix

    ./ssh.nix
    ./rclone.nix
    ./fastfetch.nix
    ./gh.nix
    ./go.nix
    ./jq.nix
    ./pandoc.nix
    ./ripgrep.nix
    ./uv.nix

    ./gpg.nix
    ./direnv.nix
    ./cc.nix

    ./fzf.nix
    ./nix.nix
    ./yazi.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    inherit username;
    # Set home directory based on the system type
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then "/Users/${username}"
      else "/home/${username}"
    );

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
