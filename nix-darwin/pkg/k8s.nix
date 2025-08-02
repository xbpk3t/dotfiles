{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 容器和虚拟化
#    docker
#    docker-compose
#    docker-credential-helpers
    # colima
    podman

    # Kubernetes 工具
    # containerd  # minikube 内置了 containerd，不需要单独安装
    minikube
    # helm 相关工具由 nixhelm 提供
    # helmfile
    # kompose
    # kube-linter
    kubectx
    kubectl
  ];
}
