---
title: ExternalDNS with OPNsense
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [k3s, networking, dns]
summary: 记录本仓库中 ExternalDNS 对接 OPNsense webhook provider 的配置步骤。
---

# ExternalDNS with OPNsense

[`ExternalDNS`](https://github.com/kubernetes-sigs/external-dns) 用来把 Kubernetes Service / Ingress 暴露信息同步到 DNS provider。

本仓库当前走 webhook provider，对接的是 OPNsense。

## Setup

### 1. Create the OPNsense Group

在 `System -> Access -> Groups` 下创建一个名为 `external-dns` 的 group。

编辑这个 group，给它加上 `Services: Unbound (MVC)` 权限。

`Services: Unbound DNS: Edit Host and Domain Override` 不够用，因为容器还需要访问 `api/unbound/status`。

### 2. Create the OPNsense User

在 `System -> Access -> Users` 下创建一个名为 `external-dns` 的 user，并注意：

- 勾选 “Generate a scrambled password to prevent local database logins for this user.”
- 把 “Login shell” 设置为 `/usr/sbin/nologin`
- 把这个 user 加入 `external-dns` group

### 3. Create the API Key

编辑刚创建的 user，新增一组 API key。后面 webhook provider 会使用这组凭据。

### 4. Create the Kubernetes Secret

在 `networking` namespace 中创建 `external-dns` Secret：

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
