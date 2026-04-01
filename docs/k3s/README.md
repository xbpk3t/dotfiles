---
title: k3s Topic Overview
type: readme
status: active
date: 2026-03-30
updated: 2026-03-30
tags: [k3s, flux, kubernetes]
summary: 汇总当前仓库中 k3s 集群的架构取舍、组件边界、常用操作与后续方向。
---

# k3s Topic Overview

本文作为 `docs/k3s/` 的总览入口，收敛该 topic 下长期有效的结论。带时间线的落地过程、排障记录和迁移复盘，继续保留为同目录下按日期命名的 review 文档。

## Scope

- 集群控制面与 GitOps 入口
- 核心网络、存储、证书与备份组件的使用边界
- 常见 secret / bootstrap 操作
- 当前 PaaS 方向的约束与草案

## Current State

- 当前集群以 `k3s + FluxCD` 为主线，强调最小 bootstrap、分层声明和逐步收敛。
- 长期稳定结论统一记录在本文件。
- 历史排障过程保留在 review 文档中，例如 [`2026-01-28-k3s-fluxcd-bootstrapping.md`](docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md)。

## GitOps Baseline

### Why FluxCD

- 当前仓库把 Flux 作为单一控制面，优先追求轻量 bootstrap、Git 原生分层和基础设施组件化管理。
- bootstrap 阶段强调“先最小可用，再逐步补齐”，因此会暂时跳过非核心栈、可选 secrets 或额外安全增强项。
- 集群同步入口独立于日常 `main` 开发分支，避免把未收敛改动直接同步进集群。

### Cluster Config and Secrets

`manifests/config/` 下仍有少量需要人工处理的 secret 操作。

Kubernetes Secret 默认按不可变对象对待。修改内容后，通常需要先删除旧 Secret，再重新应用。

#### Encrypt

```bash
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place ./cluster-secrets.example.yaml
```

#### Decrypt

```bash
sops --decrypt --in-place ./cluster-secrets.example.yaml
```

#### Edit Secrets on a New PC

把 `AGE-SECRET-KEY` 写入 `~/.config/sops/age/keys.txt`。若文件不存在，先创建。之后即可直接在本机执行 `sops` 的加解密命令。

仓库根目录的 `.sops.yaml` 已经定义了加密规则，因此本机具备 key 后，可以直接执行：

```bash
sops --encrypt --in-place [FILE]
sops --decrypt --in-place [FILE]
```

#### Common Examples

VPN Config:

```bash
kubectl -n vpn-gateway create secret generic openvpn-config --dry-run=client --from-file=vpnConfigfile=./INPUT_FILENAME.ovpn -o yaml > vpn-config.sops.yaml
sops --encrypt --in-place vpn-config.sops.yaml
```

Self-Signed CA:

```bash
kubectl -n networking create secret tls internal-ca --dry-run=client --cert=ca.crt --key=ca.key -o yaml > ca-certs.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place ca-certs.sops.yaml
```

`ca.key` 必须是无 passphrase 的私钥，可用下面命令去掉 passphrase：

```bash
openssl rsa -in ca.key -out ca2.key
```

Vault Auto-Unseal:

```bash
kubectl get secrets vault-root-token -o yaml -n apps > vault-root-token.sops.yaml
kubectl get secrets vault-keys -o yaml -n apps > vault-keys.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place vault-root-token.sops.yaml
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place vault-keys.sops.yaml
```

重新初始化前，需要先删除：

- `./secrets/vault-root-token.sops.yaml`
- `./secrets/vault-keys.sops.yaml`

并把它们从 `./kustomization.yaml` 中移除，等 cluster 初始化完成后再重新导出加密。

Authelia Keys:

```bash
openssl genrsa -out private.pem 4096
kubectl -n security create secret generic authelia-keys --dry-run=client --from-file=oidcIssuerPrivateKey=./private.pem -o yaml > authelia-keys.sops.yaml
rm private.pem
sops --encrypt --encrypted-regex '^(data|stringData)$' --in-place authelia-keys.sops.yaml
```

Jellyplist Spotify Cookie:

```bash
kubectl -n media create secret generic jellyplist-spotify-cookie --dry-run=client --from-file=vpnConfigfile=./cookies.txt -o yaml > jellyplist-spotify-cookie.sops.yaml
sops --encrypt --in-place jellyplist-spotify-cookie.sops.yaml
```

## Networking

### cert-manager

[`cert-manager`](https://github.com/cert-manager/cert-manager) 用来管理 Kubernetes 中的证书与 issuer。

- 如果只在单个 namespace 内消费，使用 `Issuer`
- 如果要跨 namespace 复用，使用 `ClusterIssuer`

两者能力基本等价，区别在于 `ClusterIssuer` 不是 namespaced resource。

### Cilium Native Routing

当前仓库在使用 Cilium native routing 时，关键 values 为：

```yaml
values:
  routingMode: native
  ipv4NativeRoutingCIDR: "${CONFIG_CLUSTER_PODS_NETWORK_IP_POOL}"
  autoDirectNodeRoutes: true
  ipam:
    mode: "kubernetes"
    operator:
      clusterPoolIPv4PodCIDRList: ["${CONFIG_CLUSTER_PODS_NETWORK_IP_POOL}"]
```

核心点：

- 使用 `routingMode: native`
- pod CIDR 与 `ipv4NativeRoutingCIDR` 保持一致
- 开启 `autoDirectNodeRoutes`
- IPAM 交给 Kubernetes 模式处理

### ExternalDNS with OPNsense

当前 ExternalDNS 通过 webhook provider 对接 OPNsense。

#### Setup

1. 在 `System -> Access -> Groups` 下创建 `external-dns` group，并赋予 `Services: Unbound (MVC)` 权限。
2. 在 `System -> Access -> Users` 下创建 `external-dns` user。
3. 勾选 “Generate a scrambled password to prevent local database logins for this user.”
4. 把 “Login shell” 设置为 `/usr/sbin/nologin`。
5. 把该 user 加入 `external-dns` group。
6. 为该 user 新建一组 API key。
7. 在 `networking` namespace 创建 `external-dns` Secret：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: external-dns
  namespace: networking
type: Opaque
stringData:
  opnsenseHost: <INSERT HOST>
  opnsenseApiKey: <INSERT API KEY>
  opnsenseApiSecret: <INSERT API SECRET>
```

### Multus Wake-on-LAN

如果要通过 Multus 附加网络发送 WOL 广播包，需要显式补一条广播路由：

```json
"routes": [{"dst": "255.255.255.255/32"}]
```

## Storage and Backup

### democratic-csi local-hostpath

[`democratic-csi`](https://github.com/democratic-csi/democratic-csi) 用来提供 resize、snapshot、clone 等 CSI 能力。

当前在单节点场景中选用 `local-hostpath` 的主要原因：

- 提供 node-local storage
- 可以借助 `idTemplate` 在重新 provision 时复用同一个 volume

这套方案只适合单节点集群，不应直接外推到多节点场景。

### MinIO Operator

常用的 console token 获取命令：

```bash
kubectl -n minio-operator get secret console-sa-secret -o jsonpath="{.data.token}" | base64 --decode
```

### VolSync

[`VolSync`](https://github.com/backube/volsync) 用来在集群内或跨集群异步复制持久卷，不依赖底层存储系统是否原生支持远程复制。

某些场景下，为了让 backup 进程获得 root 级访问权限，需要给对应 namespace 增加：

```yaml
volsync.backube/privileged-movers: "true"
```

## Authentication

### Pocket ID

[`Pocket ID`](https://pocket-id.org) 是当前集群里使用的轻量 OIDC provider，支持 passkey 登录。

首次初始化入口：

```text
https://id.${SECRET_DOMAIN}/login/setup
```

## PaaS Direction

### nixos-paas Draft

当前 `k3s + FluxCD` 作为 PaaS 的方向仍处于草案阶段，但目标是明确的：

- 用 GitOps 统一承载基础设施与应用声明
- 把集群当作稳定运行面，而不是一次性实验环境
- 逐步把网络、存储、认证、备份等能力收敛为长期可维护组件

如果后续这部分形成稳定方案，应继续把结论整理进本文件，而不是重新散落成多个无日期 guide 文件。

## References

- 历史 bootstrap / 排障记录：[`2026-01-28-k3s-fluxcd-bootstrapping.md`](docs/k3s/2026-01-28-k3s-fluxcd-bootstrapping.md)
