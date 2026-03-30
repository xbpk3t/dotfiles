---
title: k3s+fluxcd初探
type: review
status: archived
date: 2026-01-28
updated: 2026-01-28
tags:
  - k3s
  - fluxcd
  - bootstrap
summary: 按时间线记录 k3s 与 FluxCD 初次落地时的排障过程、关键命令和决策收敛。
---

# k3s + FluxCD 排障与落地记录（2026-01-28）

本文按时间顺序记录从 commit `8a4a0ad6d1c6ea97c2d553ba5d75d188b56b50fe` 到 `be0d89b4539130c050f0ec71c9e5f32f5639992e` 的排障过程。
每个小节以 commit 哈希作为标题，说明当时遇到的问题、思路、具体命令，以及重要决策。

## 6bf0f61 — Allow config kustomization to proceed without cluster-secrets

- 问题：`config` Kustomization 因缺少 `cluster-secrets` 阻断 bootstrap。
- 思路：先让核心资源跑起来，配置缺失先“可选化”以避免阻塞。
- 操作：在 config kustomization 中允许缺失 secrets。
- 重要决策：启动阶段优先保证控制面健康，后续再补齐 secrets。

## 9a55264 — Skip ca-certs kustomizations for minimal bootstrap

- 问题：CA 相关 kustomization 未准备好，导致 core 健康检查失败。
- 思路：非关键链路先禁用，缩短恢复路径。
- 操作：跳过 ca-certs 相关资源。
- 决策：先让最小集群可用，再恢复安全增强项。

## 975e672 — k3s labels and homelab sync workflow

- 问题：节点命名冲突、标签不统一，应用无法稳定调度。
- 思路：统一 inventory -> k3s flags -> 节点标签。
- 操作：对齐 role/region/zone 标签，并同步 homelab workflow。
- 决策：标签归一化为后续调度/扩展打基础。

## 3ed8185 — homelab sync script: allow no local repo

- 问题：homelab 上没有完整仓库，脚本执行失败。
- 思路：脚本允许无本地 repo，仅执行 Flux 同步。
- 操作：修改同步脚本流程。
- 决策：脚本以“最小依赖”方式运行，便于远程执行。

## 1946176 — k3s inventory unify homelab

- 问题：homelab 配置与 vps 不一致。
- 思路：统一 inventory 结构，便于复用逻辑。
- 操作：调整 inventory 定义。
- 决策：统一结构可避免后续特例分支。

## 91c05c7 — fix k8s home packages kubens

- 问题：本地工具链缺包，影响排查效率。
- 思路：补齐必要工具。
- 操作：修复 kubens 等依赖。

## ae6889f — homelab resolv.conf override

- 问题：DNS/解析异常导致镜像或依赖不可达。
- 思路：显式覆写 resolv.conf。
- 操作：在 homelab 侧添加覆盖。
- 决策：先保障基础网络可用。

## 3e0eb11 — avoid nc package conflict

- 问题：包冲突导致构建失败。
- 思路：移除冲突包/调整依赖。
- 操作：避免 nc 冲突。

## 01ab34b — k3s role labels use node.kubernetes.io

- 问题：标签命名不标准，调度不稳定。
- 思路：使用标准 `node.kubernetes.io/<role>` 标签。
- 操作：更新 label 规则。

## 3360231 — disable multus external-dns for core

- 问题：multus/external-dns 依赖未就绪导致 core 卡住。
- 思路：临时禁用非核心组件。
- 操作：注释相关资源。
- 决策：核心优先，扩展后置。

## 32937f5 — fix cilium hubble ingress and traefik mount

- 问题：Cilium/hubble/traefik 资源不完整导致失败。
- 思路：修复 ingress 与挂载配置。
- 操作：补丁修复配置。

## 3aba57e — disable cilium to unblock core networking

- 问题：Cilium 不稳定导致控制面不可用。
- 思路：回退到 k3s 默认 flannel。
- 操作：禁用 Cilium。
- 决策：先保核心网络稳定，再评估 Cilium。

## b1c2c6f — Add Flux v2.7.5 component manifests

- 操作：引入 Flux 组件清单。

## 62499dd — Add Flux sync manifests

- 操作：补齐 Flux 同步清单。

## 9806e50 — k3s: ensure iptables is installed

## 6dc189f — k3s: add pkgs param for iptables

## 57fde25 — k3s: add ipset/conntrack tools

## 1fbdb09 — k3s: ensure cni0 route

## 953e383 — k3s: use gawk in cni route unit

## 5a4daf4 — k3s: compute cni0 network with python

- 问题：CNI 路由/iptables/conntrack 缺失导致 Pod 网络异常。
- 思路：补齐基础网络工具，并自动修复 `cni0` 路由。
- 操作：
  - 安装 `iptables/ipset/conntrack`。
  - systemd oneshot 计算 Pod 网段并补路由。
- 典型命令：
  - `ip route` / `ip link show cni0`
  - `journalctl -u k3s`
- 决策：将路由修复内置化，避免手工漂移。

## 4be9f11 — k3s: disable built-in addons for flux

- 问题：k3s 内置 addon 与 Flux 管理的组件冲突。
- 思路：由 Flux 统一管理。
- 操作：禁用内置 traefik/servicelb 等。
- 决策：单一控制面避免资源“抢占”。

## 652dd38 — use built-in coredns for bootstrap

- 问题：Flux CoreDNS 与 k3s CoreDNS 冲突，导致 DNS 不可用。
- 思路：bootstrap 阶段暂用 k3s 内置 CoreDNS。
- 操作：注释 Flux CoreDNS 资源。
- 决策：DNS 必须先活，再推进其他组件。

## 291a34a — flux: avoid traefik helmrelease wait timeouts

- 问题：Traefik HelmRelease 等待超时导致反复回滚。
- 思路：禁用 HelmRelease wait。
- 操作：`disableWait/disableWaitForJobs`。
- 决策：让控制器先跑起来，后续 reconcile 修正状态。

## dae44ce — ops: align homelab flux sync with PaaS

- 问题：脚本默认分支不一致。
- 思路：统一默认分支为 PaaS。
- 操作：更新 `homelab-flux-sync.sh`。

## 163b50e — core: trim optional stacks and enable letsencrypt issuer

- 问题：tinyauth/pocket-id/volsync/prometheus/minio 等依赖缺失阻断 core。
- 思路：临时关闭非关键栈；证书用 LE。
- 操作：注释资源；启用 `letsencrypt` issuer。
- 决策：先让 memos/rsshub 线上。

## ed62d7c — core: skip empty auth/backup stacks

- 问题：kustomize 空目录报错。
- 思路：上层直接跳过空资源目录。
- 操作：在 `manifests/core/kustomization.yaml` 禁用 auth/backup。

## 2b9c506 — apps: bind memos pvc to local-hostpath

- 问题：PVC 无 StorageClass，Pod Pending。
- 思路：显式指定 `local-hostpath`。
- 操作：修改 `memos` PVC。

## 9268f68 — core: drop prometheus-crds dependencies

- 问题：prometheus-crds 未部署导致多个 kustomization 依赖卡死。
- 思路：移除依赖链。
- 操作：在 cert-manager/metrics-server/postgres/reloader 移除 `dependsOn`。

## 767b448 — networking: expose traefik via public ingress ip

## 4331492 — networking: hardcode traefik external ip for acme

- 问题：LoadBalancer EXTERNAL-IP pending；ACME HTTP-01 无法回源。
- 思路：给 Traefik Service 绑定公网 IP。
- 操作：为 Traefik Service 填充 externalIPs（最终直接写死 HK 公网 IP）。
- 典型命令：
  - `kubectl -n networking get svc traefik -o wide`
  - `curl -I http://103.85.224.63`

## be0d89b — cert-manager: switch letsencrypt to cloudflare dns01

- 问题：Cloudflare 代理返回 521，HTTP-01 验证失败。
- 思路：改用 DNS-01（Cloudflare API Token）。
- 操作：
  - 新增 `cloudflare-api-token-secret`。
  - ACME solver 切换为 DNS-01。
  - 删除旧 challenge/order/certificaterequest 触发重签。
- 典型命令：
  - `kubectl -n apps get challenge,order,certificaterequest`
  - `kubectl -n apps delete challenge,order,certificaterequest --all`
- 结果：证书签发成功，`memos-tls` / `rsshub-tls` Ready。

## 关键操作与命令摘要（按阶段）

- Flux 同步：
  - `flux reconcile source git -n flux-system flux-system`
  - `flux reconcile kustomization -n flux-system core --with-source`
  - `flux reconcile kustomization -n flux-system apps --with-source`
- 资源健康检查：
  - `kubectl get kustomizations -A`
  - `kubectl -n apps get pods -o wide`
- Traefik / Ingress：
  - `kubectl -n networking get svc traefik -o wide`
- 证书与 ACME：
  - `kubectl -n apps get certificate`
  - `kubectl -n apps get challenge,order,certificaterequest`

## **_重要决策汇总_**


### list

- **核心优先**：禁用非关键组件（Cilium、VolSync、Prometheus、tinyauth/pocket-id）确保 core 先恢复。
- **DNS 优先**：bootstrap 阶段使用 k3s 内置 CoreDNS，避免与 Flux 资源冲突。
- **最小依赖脚本**：homelab 脚本支持无本地仓库，远程 curl 执行。
- **证书策略调整**：从 HTTP-01 切换到 Cloudflare DNS-01，规避 521 回源问题。
- **网络稳定性增强**：补齐 iptables/ipset/conntrack，并自动修复 `cni0` 路由。

---

让 codex 帮我整理的，非常清晰

```markdown
**FluxCD 集群架构决策记录 (ADR 风格总结)**

### 一、明确写在仓库里的决策

- **Flux 作为单一控制面**：k3s 内置 addon 要让位给 Flux 管理，避免双重控制和平行声明漂移。
  证据在 `docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md:129` 和 `manifests/flux/flux-system/gotk-sync.yaml:3`。

- **集群只跟随 PaaS 分支**：不是直接追 `main`，而是给集群一个独立入口分支，降低误同步风险。
  证据在 `manifests/config/settings/flux.yaml:6` 和 `manifests/flux/flux-system/gotk-sync.yaml:13`。

- **公共仓库走 HTTPS，不走 SSH**：目的是减少认证链路复杂度和 bootstrap 变量。
  证据在 `manifests/flux/flux-system/gotk-sync.yaml:15`。

- **bootstrap 优先最小可用，不追求一次到位**：`cluster-secrets` 可选、CA 可先跳过、非核心栈先关。
  证据在 `docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md:19` 和 `manifests/flux/config.yaml:24`。

- **DNS 优先于其他组件**：bootstrap 阶段沿用 k3s 内置 CoreDNS，先避免和 Flux 管理的 CoreDNS 冲突。
  证据在 `docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md:136` 和 `manifests/core/networking/kustomization.yaml:3`。

- **核心优先，扩展后置**：先禁用 Cilium、Multus、ExternalDNS、Auth、VolSync 等，等 core 和 apps 稳定后再补。
  证据在 `manifests/core/kustomization.yaml:4`、`manifests/core/networking/kustomization.yaml:7`、`manifests/core/backup/kustomization.yaml:3`、`manifests/core/authentication/kustomization.yaml:4`。

- **Traefik 作为统一入口，并绑定稳定公网 IP**：不是等 LoadBalancer 自己分配，而是显式绑定公网 IP 解决 ACME/回源问题。
  证据在 `manifests/core/networking/traefik/operator/helm-release.yaml:35` 和 `docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md:181`。

- **ACME 从 HTTP-01 切到 Cloudflare DNS-01**：明确是为了解决 Cloudflare 代理导致的 521 错误。
  证据在 `manifests/core/networking/cert-manager/issuer/cluster-issuer.yaml:15` 和 `docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md:192`。

- **单节点有状态业务优先用 democratic-csi local-hostpath**：原因是 node-local、可复用 volume id，而且明确只适合单节点。
  证据在 `docs/k3s/README.md` 和 `manifests/core/storage/local-hostpath/app/helmrelease.yaml:25`。

- **memos 这类应用显式绑定 local-hostpath**：因为已经不依赖 k3s 内置 local-storage。
  证据在 `manifests/apps/memos/app/pvc.yaml:5`。

- **节点标签和 inventory 统一化**：为调度、角色区分、后续扩展做准备。
  证据在 `docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md:33`。

- **把网络修复内置化，而不是靠手工救火**：补 iptables/ipset/conntrack，并自动修复 cni0 路由。
  证据在 `docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md:107`。

- **ExternalDNS 对接 OPNsense webhook provider**：说明 DNS 自动化目标是接家庭网络里的 OPNsense，而不是云厂商 DNS。
  证据在 `docs/k3s/README.md` 和 `manifests/core/networking/external-dns/operator/helm-release.yaml:30`。

- **Multus 是为附加网络能力准备的，不是默认网络主路径**：还有 WOL 广播这种很具体的需求。
  证据在 `docs/k3s/README.md` 和 `manifests/core/networking/multus/networks/networks.yaml:7`。

- **VolSync 是备份复制方案，但依赖外部对象存储时不进入最小集**：
  证据在 `docs/k3s/README.md` 和 `manifests/core/backup/kustomization.yaml:3`。

### 二、根据结构强推断出来的决策（仅供对照记忆，不要直接当成已确认）

- **为什么是 FluxCD 而不是 ArgoCD**：仓库没有看到直接写明的 ADR，但从结构上看，更想要“控制器原语 + Git 原生声明式分层”，而不是引入一个更重的“应用平台层”。整个入口就是 `GitRepository + Kustomization + HelmRelease`，没有 Argo 的 `Application/ApplicationSet` 风格封装。
  证据见 `manifests/flux/flux-system/gotk-sync.yaml:3`、`manifests/flux/core.yaml:1`、`manifests/flux/apps.yaml:1`。

- **偏好更轻的 bootstrap 面**：公开仓库、HTTPS 拉取、可选 secrets、先最小集群可用，这些决策都更贴近 Flux 的轻量控制器思路，而不是先搭一个带 UI/应用模型的 GitOps 平台。
  证据见 `manifests/config/settings/flux.yaml:6`、`manifests/flux/config.yaml:24`、`docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md:19`。

- **把 Flux 当“可调优的基础设施组件”而不是黑盒**：还上了 `flux-operator` 和 `flux-instance`，并主动调整并发、缓存、OOMWatch。倾向于把 GitOps 控制器本身纳入同一套 infra-as-code。
  证据在 `manifests/core/gitops/flux-operator/app/helm-release.yaml:1`、`manifests/core/gitops/flux-instance/app/helm-release.yaml:1`、`manifests/core/gitops/flux-instance/app/helm-values.yaml:2`。

- **对 ArgoCD 那种 UI/平台式心智模型兴趣没那么高**：仓库里反而有 Headlamp 这类观察界面，但 GitOps 本身没有依赖一个“统一发布 UI”。这更像“运维面和 GitOps 面解耦”。（此判断偏弱，仅供参考）
```

---

### 修改几点


#### 为啥选择使用 fluxCD 而非 ArgoCD?


:::tip


毫无疑问目前ArgoCD要比 fluxCD 更主流，那为啥选择后者而非前者？


***因为目前nix社区，推荐k3s搭配的主流方案就是fluxCD***

可以看到

这个基于 fluxcd 的repo [niki-on-github/nixos-k3s](https://github.com/niki-on-github/nixos-k3s) 就比 [k3s-argocd-starter](https://github.com/mitchross/k3s-argocd-starter) 这个基于 ArgoCD 的，star更多





:::



---


```markdown
既然你上面说 ArgoCD是更主流、更强大的方案



- 组织协作成本最低：UI + 应用视角 + 审计/可见性，让“非平台团队”也能自助看状态、定位漂移、理解发布进度（你会少当人肉解释器）。
- 多租户/多集群的工程成熟度：ApplicationSet 在“规模化生成 + 多集群编排 + 团队边界”上更贴近大多数公司的真实形态。
- 处理现实世界噪声的能力更强：diff customization 这类能力在复杂 CRD/Operator 场景里非常救命（否则漂移全是红的）。
- 生态闭环更顺：要 progressive delivery 时 Argo Rollouts 是自然延伸（同一套心智/工具链）。
- 采用面更广：更容易招人、迁移、找最佳实践与第三方集成。


---

但是我现在用的比较多的 nixos + k3s 这套方案下，我看到的大部分都是用 fluxcd 这套

你可以看看是否属实？还是说我这个认知本身就是错的

无论是否属实，给我一个说法
```



<details>
<summary>dddd</summary>

```markdown


你的认知不算错：在 NixOS + k3s（尤其是 homelab / 自建集群）这条圈子里，公开样例/教程里 Flux 的出现频率确实更高，但这更多是“样本偏差 + 生态贴合度”，而不是“技术上 Flux 必然更适配 NixOS/k3s、Argo 不行”。

下面给你一个可验证的说法（带证据）+ 为什么会这样。
1) “大家都用 Flux”这件事，是否属实？

结论：在公开内容里，你看到 Flux 更多是合理现象，但无法严谨证明“绝大部分”（因为没有官方统计能专门按 NixOS+k3s 这个组合切分）。

我能给的“属实证据”是：

    NixOS 社区讨论 k3s 声明式/自建集群时，直接把 FluxCD + SOPS当成常见组合来聊，甚至有人明确描述“集群可一键销毁重建、Flux 引导后自动同步全部 manifests”。

    有实际的 NixOS+k3s 仓库把 “gitops (flux)”写进 repo 标题与 README 组件清单里（这是非常强的“公开样例偏好”信号）。

    还有明确写到“我在 NixOS 上跑 k3s，用 Flux 做 GitOps 才符合 NixOS 的声明式哲学”的教程文章。

同时也要看到反例：k3s 上用 ArgoCD 的 starter kit / 安装指南很多（只是它们通常不特别强调 NixOS）。

所以：“在 NixOS+k3s 的公开圈层里 Flux 更常见”这个观察大体成立；“绝大多数都用 Flux”无法下定量结论，但你的体感并不离谱。



2) 为什么 NixOS + k3s 圈子更容易“显得”Flux 是主流？

这不是玄学，主要是下面几条非常具体、工程上的匹配：
A. “控制器集合 + CRD 驱动”的形态更像 NixOS 的思路

NixOS 用户天然习惯“声明式 + 组合模块 + 生成配置”，Flux 的使用方式就是往集群里塞一堆 CRD（GitRepository/Kustomization/HelmRelease…）让控制器持续 reconcile——这在认知上跟 NixOS 的“系统配置即状态机”很贴合。公开教程里也会把这种“哲学一致性”当卖点讲。
B. k3s 常见场景是轻量/自建：Flux 的“默认不需要 UI”反而是优点

k3s 很多是边缘/家庭实验室/小集群，大家更愿意：

    少开一个重 UI 的控制面（资源、入口、认证、升级都要管）

    直接 Git + CRD + kubectl/监控 就够了
    这会让 Flux 在这类分享中更“顺手”，自然出现频率更高。

C. NixOS 的 k3s 模块本身就鼓励“启动阶段塞 manifests”

NixOS 社区直接提到 k3s 模块有 services.k3s.manifests / services.k3s.charts 这类启动时部署能力，用它来 bootstrap Flux很自然：先用 Nix 把 k3s 拉起来并塞进 Flux 的最小引导清单，后续全交给 Flux reconcile。

这条链路在“从裸机到可复现集群”上非常顺滑，所以 NixOS+k3s 的人更常这么写、这么教。



3) 那我该怎么理解这件事（给你一个“说法”）

你可以这么理解：

    你观察到的现象大体属实：在 NixOS+k3s 的公开样例与讨论里，Flux 的能见度更高。

    但这不等价于“Flux 技术上更正确/Argo 不适合”：更多是因为 NixOS+k3s 的典型用户画像（偏平台自建/轻量/声明式洁癖/不想要额外 UI 控制面）与 Flux 的产品形态贴合，所以内容更集中到 Flux。

    如果你是后端/有成熟 CI/CD 的团队协作环境，是否选 Flux/Argo 仍然应该回到你在上一问里要求的那套：RBAC/多租户/审计/可视化/漂移治理/规模化 Application 生成方式等，而不是被 “NixOS+k3s 圈子都这么用”牵着走。

如果你愿意我可以直接按你的约束（比如：单集群还是多集群、是否需要强多租户/RBAC、是否要求“开发自助看发布状态”、是否要 progressive delivery、是否要 OCI/Gitless）把**“NixOS+k3s 下 Flux vs Argo 的落地架构差异”**画出来：包括 bootstrap 方案、repo 结构、密钥/SOPS/age 流、回滚语义与权限边界。这样就不靠“社区体感”，而是靠你真正的工程目标来选。

```


</details>


总结如下：

***NixOS+k3s的方案里，fluxCD确实更受欢迎。但是正如上面所说，并非 fluxCD本身相较于 ArgoCD 更优，而是更契合 NixOS+k3s 的典型用户画像（偏平台自建/轻量/声明式洁癖/不想要额外 UI 控制面）***








## Ref

https://coredns.io/plugins/loop/

https://datavirke.dk/posts/bare-metal-kubernetes-part-3-encrypted-gitops-with-fluxcd/
