---
title: ClaudeSessionLimit
date: 2026-07-21
---

## 是什么

监控 Claude Code **interactive** 活 session 数量的 Hammerspoon Spoon。
超过 `maxSessions` 时 compact alert（**只提醒，不杀进程**）。结构对齐 `ChromeTabLimit`。

## 计什么 / 不计什么

**计入**：`~/.claude/sessions/<pid>.json` 中 `kind == "interactive"` 且 PID 存活（含 idle/busy/shell）。

**不计**：

| 类型 | 原因 |
|------|------|
| `kind=print` / `sdk` / 缺 kind | 非 interactive |
| 死 PID 的 interactive 残留文件 | `kill -0` 失败 |
| 同 PID 重复登记 | unique PID |
| 会话内 Agent/Task 并行 | 不占新 registry |
| 坏 JSON | 跳过，不计入 |

Fallback：绝对路径 `claude agents --json`（避开 PATH 上的 cmux wrapper）。

## 配置

| 属性 | 默认 |
|------|------|
| `enabled` | `true` |
| `maxSessions` | `12` |
| `checkInterval` | `30` |
| `sessionsDir` | `~/.claude/sessions` |
| `claudeBin` | `/etc/profiles/per-user/luck/bin/claude` |
| `kindFilter` | `"interactive"` |

## API

`:start()` / `:stop()` / `:toggle()` / `:getCount()` / `:getStatus()` / `:bindHotkeys{...}`

## 设计取舍

- **不复用 `shared_notifs`**：那是 macOS Notification；Chrome/本 spoon 用 compact `hs.alert`。
- **样式局部传入**：不改 `hs.alert.defaultStyle` 全局。
- **计数权威是 Claude registry**，不是 cmux。
- **共享节拍**：默认 `manageOwnTimer = false`，由 `init.lua` + `shared_limit_alerts.lua` 同相位调用 `checkNow()`；与 Chrome 超限 alert 同 duration（**5s**，对齐 Chrome 改 alert 后的 `tabLimitExceeded`）、先 Chrome 后 Claude。
