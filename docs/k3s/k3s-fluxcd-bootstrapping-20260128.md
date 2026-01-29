---
title: k3s+fluxcd初探
status: archive
date: 2026-01-28
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

## 重要决策汇总

- **核心优先**：禁用非关键组件（Cilium、VolSync、Prometheus、tinyauth/pocket-id）确保 core 先恢复。
- **DNS 优先**：bootstrap 阶段使用 k3s 内置 CoreDNS，避免与 Flux 资源冲突。
- **最小依赖脚本**：homelab 脚本支持无本地仓库，远程 curl 执行。
- **证书策略调整**：从 HTTP-01 切换到 Cloudflare DNS-01，规避 521 回源问题。
- **网络稳定性增强**：补齐 iptables/ipset/conntrack，并自动修复 `cni0` 路由。

## Ref

https://coredns.io/plugins/loop/

https://datavirke.dk/posts/bare-metal-kubernetes-part-3-encrypted-gitops-with-fluxcd/
