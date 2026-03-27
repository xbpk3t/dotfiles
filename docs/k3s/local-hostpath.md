---
title: democratic-csi local-hostpath Notes
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [k3s, storage, csi]
summary: 说明本仓库为什么在单节点场景下使用 democratic-csi 的 local-hostpath driver。
---

# democratic-csi local-hostpath Notes

[`democratic-csi`](https://github.com/democratic-csi/democratic-csi) 实现了 CSI 规范，可以提供 resize、snapshot、clone 等能力。

## Why `local-hostpath`

本仓库这里使用的是 `local-hostpath` driver。

选择它的主要原因是：

- 它提供 node-local storage
- 可以借助 `idTemplate` 在重新 provision 时复用同一个 volume

这套方案只适合单节点集群；多节点场景下不应把它当作通用持久化方案。
