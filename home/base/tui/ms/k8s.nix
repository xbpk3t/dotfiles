{pkgs, ...}: {
  home.packages = with pkgs; [
    # Docker
    hadolint

    # https://mynixos.com/nixpkgs/package/compose2nix
    compose2nix

    # Kubernetes 工具
    # MAYBE: fatal error: out of memory allocating arena map / failed to create OS thread 内存不够，导致整个依赖链（home-manager-path 等）被挂起。
    # minikube

    kompose
    # https://github.com/stackrox/kube-linter
    kube-linter

    # https://github.com/ahmetb/kubectx 用来快速切换context
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

    # TODO: ??? error occurred: Command "/nix/store/r9wbjib6xxjkyb9yvjvrkl4sq61i2lyn-gcc-wrapper-15.2.0/bin/cc" "-O3" "-ffunction-sections" "-fdata-sections" "-fPIC" "-m64" "-I" "/build/source/target/x86_64-unknown-linux-gnu/release/build/onig_sys-aaedb31d5d4019c3/out" "-I" "oniguruma/src" "-DHAVE_UNISTD_H=1" "-DHAVE_SYS_TYPES_H=1" "-DHAVE_SYS_TIME_H=1" "-o" "/build/source/target/x86_64-unknown-linux-gnu/release/build/onig_sys-aaedb31d5d4019c3/out/c77b18e714869709-regparse.o" "-c" "oniguruma/src/regparse.c" with args cc did not execute successfully (status code exit status: 1).
    # https://github.com/grampelberg/kty
    # kty

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

    # https://github.com/komodorio/helm-dashboard/
    helm-dashboard

    # Kubernetes 相关工具
    kubectl
    kubernetes-helm

    # https://mynixos.com/packages/kubernetes-helmPlugins

    # https://github.com/nix-community/nixhelm
    #
    #
    # https://nixos.wiki/wiki/Helm_and_Helmfile
    #
    #
    # https://github.com/redpanda-data/helm-charts

    # https://mynixos.com/nixpkgs/package/kustomize
    #
    # https://mynixos.com/nixpkgs/package/kustomize-sops
    #
    #
    kustomize
    # kind
    # minikube

    # K8s TUI
    k9s
    # 多 Pod 日志查看
    stern
    # 上下文切换
    kubectx
    # 命名空间切换：kubens 由 kubectx 包提供（二进制同包）

    # # 网络工具
    # curl
    # wget
    # httpie

    # # 监控相关
    # prometheus-cli
    # grafana-loki

    # podman-compose
    # dive # explore docker layers
    # lazydocker # Docker terminal UI.
    # skopeo # copy/sync images between registries and local storage
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

    # https://mynixos.com/nixpkgs/package/kubevirt
    #
    # virtctl
    kubevirt

    # pkgs-stable.kubernetes-helm

    # build go project to container image
    # ko
  ];

  programs = {
    # https://mynixos.com/home-manager/options/programs.k9s
    #
    #
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
              namespaces = [];
              labels = {};
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
            scopes = ["po"];
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
                  namespaces = [];
                  labels = {};
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
          scopes = ["deployments, daemonsets, statefulsets"];
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
          scopes = ["helmreleases"];
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
          scopes = ["kustomizations"];
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
          scopes = ["gitrepositories"];
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
          scopes = ["helmreleases"];
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
          scopes = ["helmrepositories"];
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
          scopes = ["ocirepositories"];
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
          scopes = ["kustomizations"];
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
          scopes = ["imagerepositories"];
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
          scopes = ["imageupdateautomations"];
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
          scopes = ["helmrelease"];
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
          scopes = ["kustomizations"];
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
