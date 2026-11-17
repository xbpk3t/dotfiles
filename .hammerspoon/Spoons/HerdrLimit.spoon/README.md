---
title: HerdrLimit
date: 2026-08-26
---

## 是什么

监控 herdr-core 内**所有未关闭（存活）agent session** 数量的 Hammerspoon Spoon。
超过 `maxSessions` 时 compact alert（**只提醒，不杀进程**）。结构对齐 `ChromeTabLimit`。

## 计什么 / 不计什么

**计入**：`hc ls --json` 的 `terminals[]` 中 `state == "live"` 且 **`status` 非空**
（agent 已通过 OSC 上报工作状态）的条数；`reported == true` 作为兜底。
跨本机 + 已连接 machine（远程地址形如 `machine/t7`），**不按 status 的具体值过滤**
（idle/working/done/blocked 都算一个 —— 语义：所有未关闭的 agent session 都占额度）。

**动态纳入**：不维护 agent 白名单；claude/codex/opencode/… 只要通过 hc 报告状态就自动计入。

**不计**：

| 类型 | 原因 |
|------|------|
| 裸 shell / 普通程序 | 没有 `status`，被过滤 |
| 未连接的 machine | `hc ls` 只列出已连接 machine，不会阻塞等待 |
| 跑在 herdr-core 之外的 agent | hc 看不到 |
| hc 未安装 / core 未运行 | 查询失败 → 计 0，不误弹 |

## remote 计数

不再需要 `enableRemote` / `remoteTargets`。在运行 Hammerspoon 的 Mac 上：

```sh
hc machine add vps        # 或 hc machine add user@host
hc machine ls
```

`hc ls --json` 会自动带出本机 + 已连接 machine 的 terminals；远程终端地址是
`machine/t7`。未连接的 machine 不会出现在结果里，也不会拖慢查询。

## 配置

| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | `true` | |
| `maxSessions` | `25` | 未关闭 agent session 总数上限 |
| `checkInterval` | `30` | status 展示用；实际节拍由 init 共享 coordinator 驱动 |
| `alertCooldown` | `60` | 秒；持续超限不重复弹，避免每 30s 刷屏 |
| `queryTimeout` | `8` | 单次 `hs.execute` 超时秒数，防挂住主线程 |
| `hcBin` | 自动探测 | 依次找 HM profile / Homebrew / `/usr/local/bin` / `~/.local/bin`，最后 `command -v hc`；找不到时计数为 0。可手动覆盖 |

## API

`:start()` / `:stop()` / `:toggle()` / `:getCount()` / `:getStatus()` / `:bindHotkeys{...}`

## 设计取舍

- **不复用 `shared_notifs`**：那是 macOS Notification；Chrome/本 spoon 用 compact `hs.alert`。
- **样式局部传入**：不改 `hs.alert.defaultStyle` 全局。
- **计数权威是 hc**（herdr-core runtime），不是本地磁盘；`hc ls` 自带已连接 machine。
- **口径**：数已报告 `status` 的 live terminal，裸 shell 自动排除；新 agent 只要上报状态就自动接入。
- **cooldown**：超限告警有 60s 冷却，不轰炸。
- **共享节拍**：由 `init.lua` + `shared_limit_alerts.lua` 同相位调用 `checkNow()`；与 Chrome 超限 alert 同 duration（**5s**）、先 Chrome 后 HerdrLimit。coordinator 的 timer 引用挂在全局 `_G.__hs_timers`。
