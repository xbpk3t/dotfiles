---
title: HearingToggle
date: 2026-04-25
---

## 是什么

`HearingToggle` 是一个用于开关 macOS `Hearing -> Background Sounds` 白噪音功能的 Hammerspoon Spoon。

## 前置条件

- `Hearing` 已添加到 macOS 菜单栏。
- Hammerspoon 已获得 `Accessibility` 权限。

## 默认热键

- `Cmd+Shift+P`

## 行为

- 成功时静默切换，不弹通知。
- 失败时显示错误通知，并记录日志。
