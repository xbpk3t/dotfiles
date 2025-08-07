{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # 容器和虚拟化
    podman

    # Kubernetes 工具
    minikube
    # helm # helm在macos上不支持用nix安装
    # helmfile
    kompose
    kube-linter # https://github.com/stackrox/kube-linter

    kubectx
    kubectl
  ];
}
