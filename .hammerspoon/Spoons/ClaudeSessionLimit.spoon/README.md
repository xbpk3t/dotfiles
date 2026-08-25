---
title: ClaudeSessionLimit
date: 2026-07-21
---

## 是什么

监控 Claude Code **活跃** session 数量的 Hammerspoon Spoon。
超过 `maxSessions` 时 compact alert（**只提醒，不杀进程**）。结构对齐 `ChromeTabLimit`。

## 计什么 / 不计什么

**计入**：`herdr agent list` 里 `agent == "claude"` 的条数，跨 workspace（本地 server + 每个 `remoteTargets` 经 `herdr --remote <t>` 累加），**不按 status 过滤**（idle/done/working/blocked 都算一个）。

**不计**：

| 类型 | 原因 |
|------|------|
| 非 claude 的 agent（codex/gemini/…） | `agent != claude` |
| 跑在 herdr 之外的 claude（非 herdr pane） | herdr 看不到 |
| 某个 remote target 查询失败 | 记 log，计 0，不拖垮整体 |
| herdr server 未运行 | 本机查询失败 → 计 0，不误弹 |

## 配置

| 属性 | 默认 |
|------|------|
| `enabled` | `true` |
| `maxSessions` | `12` |
| `checkInterval` | `30` |
| `herdrBin` | `/etc/profiles/per-user/luck/bin/herdr` |
| `remoteTargets` | `{}`（e.g. `{"user@host1"}`） |

## API

`:start()` / `:stop()` / `:toggle()` / `:getCount()` / `:getStatus()` / `:bindHotkeys{...}`

## 设计取舍

- **不复用 `shared_notifs`**：那是 macOS Notification；Chrome/本 spoon 用 compact `hs.alert`。
- **样式局部传入**：不改 `hs.alert.defaultStyle` 全局。
- **计数权威是 herdr**（agent runtime），不是 `~/.claude/sessions` 本地磁盘；天然含 remote（`herdr --remote`）。
- **共享节拍**：由 `init.lua` + `shared_limit_alerts.lua` 同相位调用 `checkNow()`；与 Chrome 超限 alert 同 duration（**5s**）、先 Chrome 后 Claude。coordinator 的 timer 引用挂在全局 `_G.__hs_timers`（chunk-local 表会被 GC，导致两个 limit 一起哑）。
