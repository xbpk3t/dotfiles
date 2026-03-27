---
title: Cilium Native Routing Notes
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [k3s, networking, cilium]
summary: 记录本仓库里 Cilium 使用 native routing 时的关键 values 配置。
---

# Cilium Native Routing Notes

[`Cilium`](https://cilium.io/) 是本仓库使用的云原生网络方案，基于 eBPF 提供网络、可观测性与安全能力。

## Native Routing

当前仓库在使用 native routing 时，需要关注下面这组 values：

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

这组配置的核心点是：

- 使用 `routingMode: native`
- pod CIDR 与 `ipv4NativeRoutingCIDR` 保持一致
- 开启 `autoDirectNodeRoutes`
- IPAM 交给 Kubernetes 模式处理
