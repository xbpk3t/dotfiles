{
  myvars,
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
    # dotbot # 用nix的mkOutOfStoreSymlink代替了
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

    # haskell
    # cabal-install
  ];

  ts = with pkgs; [
    # Node.js 生态
    nodejs
    nodePackages.eslint
    pnpm
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
    # helm # FIXME helm在macos上不支持用nix安装
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

    # [Kubernetes 基础环境要求 – 陈少文的网站](https://www.chenshaowen.com/blog/kubernetes-base-environment-requirements.html)
    # socat # 网络工具，用于在两个数据通道之间建立连接并传输数据。这些通道可以是文件、管道、设备、套接字（IPv4/IPv6, TCP, UDP, SSL）、SOCKS代理等等。它功能类似增强版的 `netcat`。
    # **`kubectl port-forward` 命令的核心依赖：** 这是 `kubectl` 最常用的功能之一，用于将本地端口转发到 Pod 中的端口，方便本地访问或调试。`kubectl port-forward` 需要 `socat` 在目标节点上运行才能建立转发隧道。
    # **容器运行时的潜在依赖：** 某些操作或特定配置的容器运行时可能内部会用到 `socat`。
    # **结论：** 没有 `socat`，`kubectl port-forward` 功能将无法工作，这对于日常运维和调试至关重要，因此是**必须安装**的。

    # conntrack # 用户空间的工具集，用于查看、管理 Linux 内核的连接跟踪表。内核的连接跟踪模块 (`nf_conntrack` 或 `nf_conntrack_ipv4`) 负责记录网络连接（如 TCP、UDP、ICMP 等）的状态信息。
    # **Service 网络的基础：** Kubernetes Service 的 `iptables` 模式（这是默认且最广泛使用的模式）严重依赖内核的连接跟踪机制来实现负载均衡和 NAT。`kube-proxy` 配置的 iptables 规则需要连接跟踪才能正确地将数据包转发到后端 Pod 并维持会话亲和性。
    # **网络策略的基础：** 像 Calico 这样的网络插件实现 NetworkPolicy 时，也可能依赖连接跟踪来确保有状态的防火墙规则正常工作。
    # **结论：** 连接跟踪是 Kubernetes Service 网络功能（服务发现、负载均衡、NAT）的基石。没有 `conntrack` *工具*（虽然内核模块是核心），`kubelet` 在启动时可能会报告错误（虽然核心功能可能还能工作，但可能不稳定或不完整），且某些网络插件或排查问题会需要它。官方文档明确要求安装，因此是**必须安装**的。

    # ebtables # 用户空间的工具集，用于配置 Linux 内核中的以太网桥防火墙规则。它在数据链路层工作，主要处理 MAC 地址相关的过滤、NAT 等。
    # **某些 CNI 插件可能需要：** 一些较老的或特定模式的容器网络接口插件可能使用 `ebtables` 来管理网桥上的流量（例如，防止 ARP 欺骗、管理 MAC 地址、配置简单的网桥防火墙规则）。
    # **Kube-proxy 的潜在需求 (极少数情况)：** 在非常早期的版本或极其特殊的配置下，`kube-proxy` 可能用到 `ebtables`，但现代版本几乎完全依赖 `iptables/nftables` 或 `ipvs`。
    # **结论：** 对于大多数现代 Kubernetes 部署，尤其是使用主流的 CNI 插件（如 Calico, Cilium 等）时，`ebtables` 并非必需。但如果使用的 CNI 插件明确要求它，或者你需要深入排查某些二层网络问题，它就很有用。因此通常是**可选，但推荐安装**，以备不时之需。

    # ipset # 用户空间的工具集，允许你管理 Linux 内核中的 IP 地址、端口、MAC 地址等的“集合”。这些集合可以被 `iptables/nftables` 高效地引用
    # **大幅提升 iptables 规则性能：** 在 Kubernetes `kube-proxy` 的 `iptables` 模式下，当集群中的 Service 和 Endpoints 数量非常庞大时，iptables 规则数量会激增，导致性能下降（数据包遍历规则链时间长）。`ipset` 允许 `kube-proxy` 将多个目标 IP 地址（如 Pod IP）分组到一个集合中，然后 iptables 规则只需要匹配这个集合一次，而不是匹配每个 IP 的单独规则，从而显著减少规则数量和匹配时间，提高网络性能。
    # **结论：** 对于小型集群，性能提升可能不明显。但对于中大型集群，使用 `ipset` 可以带来显著的网络性能提升和更稳定的响应。因此是**可选，但强烈推荐安装**，尤其在大规模部署中。

    # ipvsadm # 用户空间的工具集，用于配置和管理 Linux 内核中的 IP Virtual Server
    # **kube-proxy 的 IPVS 模式：** Kubernetes `kube-proxy` 除了默认的 `iptables` 模式，还支持 `ipvs` 模式。IPVS 是专门为高性能负载均衡设计的内核模块，它使用哈希表而不是长链规则，在处理大量 Service 时（尤其是成千上万个），性能（吞吐量、延迟、规则更新速度）通常远优于 `iptables` 模式。`ipvsadm` 是管理 IPVS 规则的必要工具。
    # **使用 IPVS 模式的前提：** 如果计划或正在使用 `kube-proxy` 的 `ipvs` 模式，那么 `ipvsadm` 是必需的，因为 `kube-proxy` 需要用它来配置内核中的 IPVS 规则。同时，`ipvs` 模式本身通常也需要依赖 `ipset` 来实现某些功能。
    # **结论：** 如果你使用 `kube-proxy` 的默认 `iptables` 模式，`ipvsadm` 不是必需的。但如果你计划使用或正在使用性能更优的 `ipvs` 模式，那么 `ipvsadm` 是**必须安装**的。即使现在不用 IPVS 模式，预先安装它为将来可能的模式切换或性能优化做准备也是明智的，因此通常是**可选，但推荐安装**。

    #    # Kubernetes 相关工具
    #    kubectl
    #    kubernetes-helm
    #    kustomize
    #    kind
    #    minikube
    #
    #    # 可选的其他工具
    #    k9s          # K8s 终端 UI
    #    stern        # 多 Pod 日志查看
    #    kubectx      # 上下文切换
    #    kubens       # 命名空间切换
    #
    #    # 数据库客户端
    #    mysql-client
    #    postgresql
    #
    #    # 网络工具
    #    curl
    #    wget
    #    httpie
    #
    #    # 监控相关
    #    prometheus-cli
    #    grafana-loki
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
  # Temporarily inline core configuration to avoid Nix store path issues
  # imports = [
  #   ./core
  # ];

  home.packages = all;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    username = myvars.username;
    # Set home directory based on the system type
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then "/Users/${myvars.username}"
      else "/home/${myvars.username}"
    );

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = lib.mkDefault "24.05";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
