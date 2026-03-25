---
title: Pocket ID Setup Note
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [k3s, authentication, oidc]
summary: 记录 Pocket ID 在当前集群中的初始 setup 入口。
---

# Pocket ID Setup Note

[`Pocket ID`](https://pocket-id.org) 是一个简洁的 OIDC provider，支持基于 passkey 的登录。

## Setup

首次初始化时，可以使用 admin 账号访问：

```text
https://id.${SECRET_DOMAIN}/login/setup
```
