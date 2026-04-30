---
title: sing-box Rule 模式下 FakeIP 间歇性超时的排查复盘
type: review
status: active
date: 2026-04-17
updated: 2026-04-17
isOriginal: false
tags:
  - sing-box
  - fakeip
  - rule
  - review
  - troubleshooting
---

:::tip[TLDR]

这次问题分成两层：

1. 第一层（稳定复现）：`Rule` 模式下特定站点卡在 TLS 握手，`global` 正常。根因是 `route.rules` 里的 `ip_is_private = true -> direct` 会误伤 FakeIP（`198.18.0.0/15` / `fc00::/18`）。
2. 第二层（修复后偶发）：同一站点有时成功有时超时，属于运行态/链路抖动，不再是同一个规则错误。

最终修复是最小改动：在 `ip_is_private` 规则之前，显式把 FakeIP 网段路由到 `select`。

:::

## 问题定义

现象是：

- `curl -Iv https://x.com`、`curl -Iv https://asmrmoon.com` 在 `Rule` 模式下会卡住（有时超时，有时可恢复）。
- 切换 `global` 后可访问。
- 体感上问题出现在一次 sing-box server rebuild 之后。

目标不是“先绕过去”，而是把根因定位清楚，再做最小修复。

## 初始假设

排查开始时，列了 5 类可能性：

1. 站点本身不可用。
2. 本机 DNS 或 FakeIP 机制异常。
3. VPS 上 sing-box server rebuild 引入了配置问题。
4. 客户端 route/dns 规则冲突。
5. 运行态抖动（TUN/selector/节点质量波动）。

## 排查路径（假设 -> 实验 -> 结论）

### 1) 先排除“站点自身故障”

实验：直接连真实 IP 做对照（`--resolve`）。

```bash
curl -4 -Ivs --max-time 12 --resolve asmrmoon.com:443:104.21.39.44 https://asmrmoon.com/
```

结果：可成功返回 `HTTP/2 200`。

结论：站点并未整体故障。

### 2) 排除“VPS server 端彻底坏掉”

实验：SSH 到节点本机测试。

```bash
ssh luck@142.171.154.61
curl -4 -Ivs --max-time 10 https://x.com
curl -4 -Ivs --max-time 10 https://asmrmoon.com
```

结果：两站在 VPS 上都能完成 TLS 握手。

结论：server 出站能力本身是可用的，rebuild 与故障更像“时间相关”而非“直接因果”。

### 3) 模式隔离：判断问题发生在哪一层

实验：强制 `global`，并固定一个健康节点后测试两站。

结果：

- `asmrmoon.com` 返回 `HTTP/2 200`
- `x.com` 返回 `HTTP/2 403`（连接成功，业务层响应）

结论：代理链路本身可用；问题集中在 `Rule + FakeIP` 路径，不是“节点完全不可用”。

### 4) 核验 live 配置，避免“以为改了其实没生效”

实验：读取 `/run/secrets/rendered/singbox-client.json`。

关键字段确认：

- `mode = Rule`
- `dns.fakeip` 启用（`198.18.0.0/15`, `fc00::/18`）
- `route.rules` 存在 `ip_is_private = true -> direct`

结论：FakeIP + 私网直连并存，且有潜在冲突面。

### 5) 锁定第一层根因：FakeIP 被私网直连误伤

症状对应关系：

- `Rule` 下域名经常被解析到 FakeIP（`198.18.x.x` / `fc00::...`）。
- 一旦后续路由把这类地址按私网处理送到 `direct`，就会出现 TLS 握手卡住/超时。

结论：这是配置语义冲突，不是站点问题。

## 修复方案（最小改动）

只改 `lib/singbox/route.nix` 一处，在 `ip_is_private` 前增加显式例外：

```nix
{
  ip_cidr = [
    "198.18.0.0/15"
    "fc00::/18"
  ];
  action = "route";
  outbound = "select";
}
{
  ip_is_private = true;
  action = "route";
  outbound = "direct";
}
```

这不是站点特判，而是修复规则边界。

## 修复验证闭环

### 静态验证

- 渲染配置中确认新规则已存在，且顺序在 `ip_is_private` 之前。

### 动态验证

- `Rule` 模式下连续回归：
  - `x.com` 连续返回 `HTTP/2 403`（连接成功）
  - `asmrmoon.com` 连续返回 `HTTP/2 200`

### 反证验证

- `global` 模式始终可访问，说明不是“server 坏”。

## 为什么后来又出现“时好时坏”

修复后仍观察到“同一域名有时成功、有时超时/重置”。

这个阶段的特征和第一层根因不同：

- 不是稳定可复现的规则误命中；
- 更像运行态/链路波动（节点质量、TUN 恢复窗口、瞬时网络状态）。

因此最终判断是双层问题：

1. 规则冲突（已修复，确定因果）。
2. 运行态抖动（需要运行态观测，不应继续乱改规则）。

## 本次复盘的可复用结论

1. `global` 正常 + `Rule` 失败，优先查客户端分流链而不是先怀疑 server。
2. FakeIP 场景里，`ip_is_private` 是高风险规则，必须明确 FakeIP 网段例外。
3. 先做“根因修复”，不要直接堆域名特判 patch。
4. 修复后如果变成“间歇性”，要切换到运行态诊断思路，不要继续配置层过拟合。

## 附：下次复现时的最小诊断清单

```bash
# 1) 当前模式与选择节点
curl -s -H "Authorization: Bearer <secret>" http://127.0.0.1:9090/configs
curl -s -H "Authorization: Bearer <secret>" http://127.0.0.1:9090/proxies/select

# 2) Rule 下快速回归
curl -4 -Ivs --max-time 8 https://x.com
curl -4 -Ivs --max-time 8 https://asmrmoon.com

# 3) 切 global 做分层隔离
curl -X PATCH -H "Authorization: Bearer <secret>" -H 'Content-Type: application/json' \
  -d '{"mode":"global"}' http://127.0.0.1:9090/configs

# 4) 若仍异常，再看运行态（不先改配置）
sudo launchctl print system/local.singbox.tun
sudo tail -n 200 /tmp/singbox.log
```
