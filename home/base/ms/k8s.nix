{ pkgs, ... }:
{
  home.packages =
    with pkgs;
    [
      # 分类1：Kubernetes 核心与生态工具
      compose2nix

      # Kubernetes 工具

      # [2026-05-28] 暂不考虑把 minikube 加回来，目前有两条更清晰的 k8s路线：
      #  1. macOS/桌面临时容器环境：colima，而且 colima.yaml 里已有 k3s-style Kubernetes 配置，只是 enabled: false。
      #  2. VPS/homelab/真实节点：modules/nixos/extra/k3s，这是更符合你现在 infra 方向的长期方案。
      #
      #- minikube dashboard # 启动 Minikube 的 Kubernetes dashboard
      #- minikube start --driver=docker --container-runtime=docker # 使用 Docker 作为虚拟化程序和容器运行时启动 Minikube
      #- eval $(minikube docker-env) # 设置环境变量，使得 Docker 能够构建和运行 Minikube 中的镜像
      #- minikube addons list # 列出所有可用的 Minikube 插件（addons）
      # minikube

      # # [kubernetes/kompose：将 Compose 转换为 Kubernetes](https://github.com/kubernetes/kompose)
      kompose

      # https://github.com/stackrox/kube-linter
      kube-linter

      # https://github.com/ahmetb/kubectx 用来快速切换context
      # 上下文切换
      kubectx
      # https://github.com/sbstp/kubie
      kubie
      kubectl
      # https://github.com/txn2/kubefwd
      kubefwd
      # https://github.com/robscott/kube-capacity 颇为实用的工具。k8s的命令行工具kubectl用来查看集群的整体资源情况往往操作会比较复杂，可能需要多条命令配合在一起才能拿得到想要的结果。kube-capacity命令行工具用来快速查看集群中的资源使用情况，包括node、pod维度。
      kube-capacity

      kubernetes-polaris
      conftest

      # https://github.com/steveteuber/kubectl-graph  最近接手了一个规模比较大的集群，光是整理集群中的资源就使人头昏眼花，虽然我自认 kubectl 使用的已经十分熟练，但是上千个 k8s Resource 看下来还是不堪重负。在不能为集群安装任何其他工具的情况下，可以改造的就只有我自己的 Client 端，也就是 kubectl 了。本文就介绍一个有趣的 kubectl 插件：kubectl-graph。
      kubectl-graph

      # https://github.com/cilium/cilium-cli
      #  一键安装 Cilium：自动检测集群类型（如 minikube、GKE、EKS）并适配配置。
      #  集群诊断：运行连接性测试（cilium connectivity test）、查看状态（cilium status）。
      #  高级功能管理：启用 Hubble（网络流量可视化）、ClusterM esh（多集群互联）、IPsec 加密等。
      #  版本管理：支持安装/升级到指定 Cilium 版本。
      cilium-cli

      kubebuilder
      # 该项目脱胎于 mergeKubeConfig 项目，最早写该项目的目的是在一堆杂乱无章的 kubeconfig 中自由的切换。随着需要操作的 k8s 集群越来越多，在不同的集群之间切换也越来越麻烦，而操作 k8s 集群的本质不过是通过 kubeconfig 访问 k8s 集群的 API Server，以操作 k8s 的各种资源，而 kubeconfig 不过是一个 YAML 文件，用来保存访问集群的密钥，最早的 mergeKubeConfig 不过是一个操作 YAML 文件的 Python 脚本。而随着 Go 学习的深入，也就动了重写这个项目的念头，就这样 kubecm 诞生了。
      kubecm

      # kubecfg is a CLI tool for managing Kubernetes kubeconfig files with fast context switching, namespace management, and multi-config merging through an interactive TUI
      kubecfg
    ]
    ++ [
      # 分类2：Kubernetes 节点依赖说明与 Kustomize 工具
      #
      #
      #
      kustomize
      # kind

      # 多 Pod 日志查看
      stern

      # 命名空间切换：kubens 由 kubectx 包提供（二进制同包）
    ]
    ++ [
      # 分类3：扩展候选与补充工具

      # # 监控相关
      # prometheus-cli
      # grafana-loki

      # podman-compose

      # copy/sync images between registries and local storage
      # 一个命令行工具，用于在不同的容器镜像仓库之间复制、检查和删除容器镜像
      # https://github.com/containers/skopeo
      # skopeo
      # go-containerregistry # provides `crane` & `gcrane`, it's similar to skopeo

      # kubectl
      # kubectx # kubectx & kubens
      # kubie # same as kubectl-ctx, but per-shell (won’t touch kubeconfig).
      # kubectl-view-secret # kubectl view-secret
      # kubectl-tree # kubectl tree
      # kubectl-node-shell # exec into node
      # kubepug # kubernetes pre upgrade checker
      # kubectl-cnpg # cloudnative-pg's cli tool

      # kubebuilder
      # istioctl
      # clusterctl # for kubernetes cluster-api

      #
      # virtctl
      kubevirt

      # build go project to container image
      #- url: https://github.com/ko-build/ko
      #  doc: https://ko.build/
      #  des: 专门用来打包golang应用容器的image的工具，被很多k8s生态下的主流OSS使用
      # ko

      # kor

      kustomize-sops
    ];

  programs = {
    # K8s TUI
    # https://mynixos.com/home-manager/options/programs.k9s
    # [2026-04-04] https://github.com/grampelberg/kty k9s 功能远比 kty 丰富且成熟。支持资源浏览、日志、shell、端口转发、编辑 YAML、批量操作、自定义视图等，界面类似 kty 的仪表板，但操作更流畅、快捷键丰富、支持多集群切换。所以移除掉kty
    k9s = {
      enable = true;
      skins = {
        default = {
          k9s = {
            body = {
              fgColor = "dodgerblue";
            };
          };
        };
      };
      views = {
        # Move all nested views directly under programs.k9s.views
        "v1/pods" = {
          columns = [
            "AGE"
            "NAMESPACE"
            "NAME"
            "IP"
            "NODE"
            "STATUS"
            "READY"
          ];
        };
      };

      aliases = {
        dp = "deployments";
        sec = "v1/secrets";
        jo = "jobs";
        cr = "clusterroles";
        crb = "clusterrolebindings";
        ro = "roles";
        rb = "rolebindings";
        np = "networkpolicies";
      };

      settings = {
        k9s = {
          liveViewAutoRefresh = false;
          refreshRate = 2;
          maxConnRetry = 5;
          readOnly = false;
          noExitOnCtrlC = false;
          ui = {
            enableMouse = false;
            headless = false;
            logoless = false;
            crumbsless = false;
            reactive = false;
            noIcons = false;
          };
          skipLatestRevCheck = false;
          disablePodCounting = false;
          shellPod = {
            image = "busybox";
            namespace = "default";
            limits = {
              cpu = "100m";
              memory = "100Mi";
            };
          };
          imageScans = {
            enable = false;
            exclusions = {
              namespaces = [ ];
              labels = { };
            };
          };
          logger = {
            tail = 100;
            buffer = 5000;
            sinceSeconds = -1;
            textWrap = false;
            showTime = false;
          };
          thresholds = {
            cpu = {
              critical = 90;
              warn = 70;
            };
            memory = {
              critical = 90;
              warn = 70;
            };
          };
        };

        plugins = {
          # Renamed from plugin to plugins
          fred = {
            shortCut = "Ctrl-L";
            description = "Pod logs";
            scopes = [ "po" ];
            command = "kubectl";
            background = false;
            args = [
              "logs"
              "-f"
              "$NAME"
              "-n"
              "$NAMESPACE"
              "--context"
              "$CLUSTER"
            ];
          };

          settings = {
            k9s = {
              liveViewAutoRefresh = true;
              refreshRate = 2;
              maxConnRetry = 5;
              readOnly = false;
              noExitOnCtrlC = false;
              ui = {
                enableMouse = false;
                headless = false;
                logoless = false;
                crumbsless = false;
                reactive = false;
                noIcons = false;
              };
              skipLatestRevCheck = false;
              disablePodCounting = false;
              shellPod = {
                image = "busybox";
                namespace = "default";
                limits = {
                  cpu = "100m";
                  memory = "100Mi";
                };
              };
              imageScans = {
                enable = false;
                exclusions = {
                  namespaces = [ ];
                  labels = { };
                };
              };
              logger = {
                tail = 100;
                buffer = 5000;
                sinceSeconds = -1;
                textWrap = false;
                showTime = false;
              };
              thresholds = {
                cpu = {
                  critical = 90;
                  warn = 70;
                };
                memory = {
                  critical = 90;
                  warn = 70;
                };
              };
            };
          };
        };

        krr = {
          shortCut = "Shift-K";
          description = "Get krr";
          scopes = [ "deployments, daemonsets, statefulsets" ];
          command = "bash";
          background = false;
          confirm = false;
          args = [
            "-c"
            "LABELS=$(kubectl get $RESOURCE_NAME $NAME -n $NAMESPACE --context $CONTEXT --show-labels | awk '{print $NF}' | awk '{if(NR>1)print}'); krr simple --cluster $CONTEXT --selector $LABELS; echo \"Press 'q' to exit\"; while : ; do read -n 1 k <&1; if [[ $k = q ]] ; then break; fi; done"
          ];
        };

        toggle-helmrelease = {
          shortCut = "Shift-T";
          confirm = true;
          scopes = [ "helmreleases" ];
          description = "Toggle to suspend or resume a HelmRelease";
          command = "bash";
          background = false;
          args = [
            "-c"
            "suspended=$(kubectl --context $CONTEXT get helmreleases -n $NAMESPACE $NAME -o=custom-columns=TYPE:.spec.suspend | tail -1); verb=$([ $suspended = \"true\" ] && echo \"resume\" || echo \"suspend\"); flux $verb helmrelease --context $CONTEXT -n $NAMESPACE $NAME | less -K"
          ];
        };

        toggle-kustomization = {
          shortCut = "Shift-T";
          confirm = true;
          scopes = [ "kustomizations" ];
          description = "Toggle to suspend or resume a Kustomization";
          command = "bash";
          background = false;
          args = [
            "-c"
            "suspended=$(kubectl --context $CONTEXT get kustomizations -n $NAMESPACE $NAME -o=custom-columns=TYPE:.spec.suspend | tail -1); verb=$([ $suspended = \"true\" ] && echo \"resume\" || echo \"suspend\"); flux $verb kustomization --context $CONTEXT -n $NAMESPACE $NAME | less -K"
          ];
        };

        reconcile-git = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = [ "gitrepositories" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            "flux reconcile source git --context $CONTEXT -n $NAMESPACE $NAME | less -K"
          ];
        };

        reconcile-hr = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = [ "helmreleases" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            "flux reconcile helmrelease --context $CONTEXT -n $NAMESPACE $NAME | less -K"
          ];
        };

        reconcile-helm-repo = {
          shortCut = "Shift-Z";
          description = "Flux reconcile";
          scopes = [ "helmrepositories" ];
          command = "bash";
          background = false;
          confirm = false;
          args = [
            "-c"
            "flux reconcile source helm --context $CONTEXT -n $NAMESPACE $NAME | less -K"
          ];
        };

        reconcile-oci-repo = {
          shortCut = "Shift-Z";
          description = "Flux reconcile";
          scopes = [ "ocirepositories" ];
          command = "bash";
          background = false;
          confirm = false;
          args = [
            "-c"
            "flux reconcile source oci --context $CONTEXT -n $NAMESPACE $NAME | less -K"
          ];
        };

        reconcile-ks = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = [ "kustomizations" ];
          command = "bash";
          background = false;
          args = [
            "-c"
            "flux reconcile kustomization --context $CONTEXT -n $NAMESPACE $NAME | less -K"
          ];
        };

        reconcile-ir = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = [ "imagerepositories" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "flux reconcile image repository --context $CONTEXT -n $NAMESPACE $NAME | less -K"
          ];
        };

        reconcile-iua = {
          shortCut = "Shift-R";
          confirm = false;
          description = "Flux reconcile";
          scopes = [ "imageupdateautomations" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "flux reconcile image update --context $CONTEXT -n $NAMESPACE $NAME | less -K"
          ];
        };

        get-suspended-helmreleases = {
          shortCut = "Shift-S";
          confirm = false;
          description = "Suspended Helm Releases";
          scopes = [ "helmrelease" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "kubectl get --context $CONTEXT --all-namespaces helmreleases.helm.toolkit.fluxcd.io -o json | jq -r '.items[] | select(.spec.suspend==true) | [.metadata.namespace,.metadata.name,.spec.suspend] | @tsv' | less -K"
          ];
        };

        get-suspended-kustomizations = {
          shortCut = "Shift-S";
          confirm = false;
          description = "Suspended Kustomizations";
          scopes = [ "kustomizations" ];
          command = "sh";
          background = false;
          args = [
            "-c"
            "kubectl get --context $CONTEXT --all-namespaces kustomizations.kustomize.toolkit.fluxcd.io -o json | jq -r '.items[] | select(.spec.suspend==true) | [.metadata.name,.spec.suspend] | @tsv' | less -K"
          ];
        };
      };
    };
    kubecolor = {
      enable = true;
      enableAlias = true;
    };
  };
}
