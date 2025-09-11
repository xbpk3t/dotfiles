{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
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
}
