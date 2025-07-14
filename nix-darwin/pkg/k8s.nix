{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
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
  ];
}

# TODO [nix-community/nixhelm: This is a collection of helm charts in a nix-digestable format. [maintainers=@farcaller, @e1senh0rn]](https://github.com/nix-community/nixhelm) 用nixhelm安装helm相关
