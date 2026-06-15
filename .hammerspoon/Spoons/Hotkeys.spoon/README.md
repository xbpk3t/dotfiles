# Hotkeys.spoon

Alfred CASK workflow 的 Hammerspoon 原生替代。
提供 app 启动热键和 Chrome 标签页功能。

## 热键

| 按键 | 功能 | 备注 |
|------|------|------|
| `⌘1` | 启动/切换 Finder | |
| `⌘2` | 启动/切换 Chrome | |
| `⌘3` | 启动/切换 GoLand | |
| `⌘0` | 启动/切换 Cmux | |
| `⌘⇧D` | Chrome tab → Markdown 链接 | 复制当前 tab 的 `[标题](url)` 到剪贴板 |
| `⌘E` | Chrome Recent Tabs | 类似 IntelliJ `⌃⇥`，在两个最近标签页间 toggle |

## Chrome Recent Tabs

`⌘E` 在 Chrome 前台时生效，实现标签页级的快速前后切换：

- **首次按** → 跳到最后一个 tab
- **再按** → 跳回之前的 tab
- **连续按** → 在两个 tab 间稳定 toggle
- **per-window 跟踪** → 不同 Chrome 窗口各自独立记录
- **非 Chrome 应用** → 静默放行，不干扰 `⌘E` 的其他用途

### 行为细节

- 仅 1 个 tab 时静默跳过
- 历史 tab 被关闭后自动重置，下次按跳到最后一个 tab
- Chrome 退出时自动清空历史记录
- 错误/降级通过 `hs.logger`（Console.app 搜 `Hotkeys`）记录

## 配置

所有 Chrome 相关功能可通过 `_config.chrome.enabled` 一键开关：

```lua
obj._config = {
  chrome = {
    enabled = true,  -- 设为 false 禁用所有 Chrome 功能
  },
}
```

设 `false` 后 `⌘⇧D`、`⌘E` 和 Chrome watcher 均不生效。
