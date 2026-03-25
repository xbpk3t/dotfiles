---
title: MinIO Operator Notes
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [k3s, storage, minio]
summary: 记录 MinIO operator 场景下常用的 console token 获取命令。
---

# MinIO Operator Notes

[`MinIO`](https://github.com/minio/minio) 是高性能对象存储，兼容 S3 API。

## Get Console JWT

```bash
kubectl -n minio-operator get secret console-sa-secret -o jsonpath="{.data.token}" | base64 --decode
```
