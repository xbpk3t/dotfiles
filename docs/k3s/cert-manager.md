---
title: cert-manager Issuer Notes
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [k3s, networking, tls]
summary: 简要说明本仓库中 cert-manager 里 Issuer 与 ClusterIssuer 的使用边界。
---

# cert-manager Issuer Notes

[`cert-manager`](https://github.com/cert-manager/cert-manager) 用来管理 Kubernetes 中的证书与 issuer。

## Issuer vs ClusterIssuer

如果只想在单个 namespace 内消费，可以使用 `Issuer`。

如果希望一个 issuer 被多个 namespace 共享，则应使用 `ClusterIssuer`。它和 `Issuer` 基本等价，但不是 namespaced resource，因此可以跨 namespace 签发证书。
