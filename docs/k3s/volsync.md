---
title: VolSync Notes
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [k3s, backup, storage]
summary: 记录 VolSync 在当前集群里需要额外注意的 namespace annotation。
---

# VolSync Notes

[`VolSync`](https://github.com/backube/volsync) 用来在集群内或跨集群异步复制持久卷，并且不依赖底层存储系统自身是否支持远程复制。

## Namespace Annotation

某些场景下，为了让 backup 进程拿到 root 级访问权限，需要在对应 namespace 的 `annotations` 中加入：

```yaml
volsync.backube/privileged-movers: "true"
```
