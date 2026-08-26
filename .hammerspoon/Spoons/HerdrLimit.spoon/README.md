---
title: HerdrLimit
date: 2026-08-26
---

## 是什么

监控 herdR 内**所有未关闭（存活）agent session** 数量的 Hammerspoon Spoon。
超过 `maxSessions` 时 compact alert（**只提醒，不杀进程**）。结构对齐 `ChromeTabLimit`。

## 计什么 / 不计什么

**计入**：`herdr agent list` 里 **`agent` 为非空字符串**的 pane 数（= 已被 herdR 识别为 agent 的 session），
跨 workspace（本地 server + 每个 `remoteTargets` 经 `herdr --remote <t>` 累加），**不按 status 过滤**（idle/working/done/blocked 都算一个 —— 语义：所有未关闭的 session 都占额度）。

**动态纳入**：不维护 agent 白名单，直接数 `result.agents[]` 中 `agent` 非空的条数。
herdr 无论以后支持多少种 agent（claude/codex/copilot/devin/droid/kimi/opencode/kilo/hermes/qodercli/cursor/mastracode/antigravity-cli/grok/…），
只要出现在 `agent list` 里**自动计入**，无需改配置、永不掉队。

**不计**：

| 类型 | 原因 |
|------|------|
| 非 agent 的 pane / 裸终端 | `agent` 字段为空，被过滤 |
| 跑在 herdr 之外的 agent | herdr 看不到 |
| 某个 remote target 查询失败 | 记 log，计 0，不拖垮整体 |
| herdr server 未运行 | 本机查询失败 → 计 0，不误弹 |

## remote 开关

默认 `enableRemote = false`，**完全不碰 `--remote` 分支**（连命令都不拼），零阻塞。
只有同时设置 `enableRemote = true` 且 `remoteTargets` 非空时，才逐个 `herdr --remote <t> agent list` 累加。

## 配置

| 属性 | 默认 | 说明 |
|------|------|------|
| `enabled` | `true` | |
| `maxSessions` | `25` | 未关闭 agent session 总数上限 |
| `checkInterval` | `30` | status 展示用；实际节拍由 init 共享 coordinator 驱动 |
| `alertCooldown` | `60` | 秒；持续超限不重复弹，避免每 30s 刷屏 |
| `queryTimeout` | `6` | 单次 `hs.execute` 超时秒数，防挂住主线程 |
| `herdrBin` | `/etc/profiles/per-user/luck/bin/herdr` | |
| `enableRemote` | `false` | 是否跑 remote 计数 |
| `remoteTargets` | `{}`（e.g. `{"user@host1"}`） | 仅在 `enableRemote=true` 生效 |

## API

`:start()` / `:stop()` / `:toggle()` / `:getCount()` / `:getStatus()` / `:bindHotkeys{...}`

## 设计取舍

- **不复用 `shared_notifs`**：那是 macOS Notification；Chrome/本 spoon 用 compact `hs.alert`。
- **样式局部传入**：不改 `hs.alert.defaultStyle` 全局。
- **计数权威是 herdr**（agent runtime），不是本地磁盘；天然含 remote（`herdr --remote`）。
- **动态口径**：数 `agent` 非空条数而非维护白名单 → 新 agent 自动接、裸 pane 自动排除。
- **cooldown**：超限告警有 60s 冷却，不轰炸。
- **remote 开关**：默认关→零阻塞风险；开启才有 `--remote` 开销，且每条带 timeout。
- **共享节拍**：由 `init.lua` + `shared_limit_alerts.lua` 同相位调用 `checkNow()`；与 Chrome 超限 alert 同 duration（**5s**）、先 Chrome 后 HerdrLimit。coordinator 的 timer 引用挂在全局 `_G.__hs_timers`。
