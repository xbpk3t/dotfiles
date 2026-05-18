---
title: HearingToggle
date: 2026-04-25
updatedAt: 2026-05-17
---

## 是什么

`HearingToggle` 是一个用于开关 macOS `Background Sounds` 白噪音功能的 Hammerspoon Spoon。

## 前置条件

- Hammerspoon 已获得 `Accessibility` 权限。

## 默认热键

- `Cmd+Shift+F8` Toggle开关 (Play/Pause)
- `Cmd+Shift+F7/F9` Prev/Next

## CHANGELOG

### v1.1.0 [2026-05-17]


#### 设计

- **生命周期托管**：Lua 通过 `hs.task` 直接持有 worker 进程，而非 detached shell / `nohup`
- **输入兜底**：同时接住媒体键和 F7/F8/F9，兼容不同键盘模式下顶排键的输出行为
- **兼容层**：`smartToggle` / `smartNext` / `smartPrev` 保留为别名，旧调用方无需修改



#### 关键决策

> 为什么不用 `Hearing` 菜单栏方案了？


之前是通过“模拟点击”来实现该功能：从 MenuBar对应icon的对应位置作为入口，模拟点击。但是这个方案显而易见的不稳定。

正好搜到了

[cli activation of built-in white noise on macos](https://gist.github.com/dsanson/9907c07b1441c676720c34f02301225b)

这个shell

才知道其实可以直接用命令来调用，要比现在的方案简单很多。***所以直接把这个改写成nushell了***


简单来说：旧方案同时依赖系统 UI 结构、菜单栏状态和 Accessibility 树，太过脆弱，macOS 面板结构变化就容易失效。直接控制 `Background Sounds` worker 绕开了这层间接依赖。


---


> ***为什么一开始用 nushell，后来又改成 Lua 了？***

***这是一个很关键的问题。也是一开始的设计缺陷。***

***nushell `nohup`/后台化方案在实机上暴露出空 PID、状态判断失真、二次 toggle 失效等问题。***

简单来说，仍然是控制权的问题，nushell里用worker处理 `Toggle开关`，结果开了之后，worker进程的pid找不到了，也就无法再做关闭操作。

Lua 通过 `hs.task` 直接持有 worker 进程后，开关和切换才真正可控。nushell 仍保留为播放 worker，只是不再承担生命周期管理。




---

> 为什么移除 `nowplaying-cli`？

我一开始以为 `nowplaying-cli` 可以直接判断当前宿主机所有服务是否 `now-playing`，但是实现完成后发现，只能判断 `Music APP` 或者 `spotify desktop APP` 这种的状态。无法处理 浏览器 WebPlayer 当前是否正在播放音乐。

当时的情况是，***hs会优先劫持 `F8`这个媒体控制键，导致在 WebPlayer 播放时，即使按该key也无法 Pause 掉 WebPlayer 里正在播放的音乐。在按下 `F8`之后，只会用来开关这个白噪音，再也无法控制Mac做其他 Voice Control了***。也就是说键位冲突了。




---

> 为什么要显式 `afplay` 进程清理？

macOS 下子进程可能脱离父进程继续存活。只杀主 worker 不清理 `afplay`，会导致「逻辑上已关闭但声音还在」或多次切换后叠音。



---
