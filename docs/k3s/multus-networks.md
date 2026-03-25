---
title: Multus Networks Wake-on-LAN Note
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags: [k3s, networking, multus]
summary: 记录通过 Multus 网络发送 Wake-on-LAN 广播包时需要补的静态路由。
---

# Multus Networks Wake-on-LAN Note

## Wake-on-LAN

如果要通过 Multus 附加网络发送 WOL 广播包，需要为 `255.255.255.255/32` 增加一条路由：

```json
"routes": [{"dst": "255.255.255.255/32"}]
```
