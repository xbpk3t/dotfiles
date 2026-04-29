---
title: ChromeTabLimit
date: 2026-04-20
---

## 是什么

`ChromeTabLimit` 是一个用于限制 Chrome 标签页数量的 Hammerspoon Spoon。
它会按固定间隔检查标签页总数，超过阈值后执行提醒或自动处理。

## 功能点

- 周期性统计所有 Chrome 窗口中的标签页总数。
- 超过 `maxTabs` 时发出提示。
- 可选自动关闭超出的标签页（`autoCloseExcessTabs = true`）。
- 提供启停、开关切换、状态查看和热键绑定能力。

## 关键配置

- `enabled`: 是否启用该 Spoon。
- `maxTabs`: 允许的最大标签页数量。
- `checkInterval`: 检查间隔（秒）。
- `autoCloseExcessTabs`: 是否自动关闭超出阈值的标签页。
- `chromeAppName`: 目标浏览器应用名（默认 `Google Chrome`）。

## 设计决策

### 使用 compact Alert 而非 Notification

之前会认为

```markdown
- 1、ChromeTabLimit 的提示是 schedule 提示，并且内容很多（导致面积很大），如果做成 Alert，就会导致造成遮挡，很干扰正常使用。
- 2、Notification 可以通过开启 `Focus Mode`免打扰来mute，但是 Alert 则除非关掉 hs，否则无法mute。前者更灵活。
```

但是实际体验中存在问题

确实不再干扰网页正文浏览，但是会遮挡住右上侧，***且需要自己手动点掉***。所以在想，既然 alter面积太大，那我做成 mini size不就行了吗？

所以做成了 Compact Alert
