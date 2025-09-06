# WiFi 音频控制模块

## 概述

这个模块提供智能的音频控制功能，根据 WiFi 网络连接状态和耳机连接状态自动调整系统音量。主要用于保护隐私，防止在不受信任的网络环境中意外播放音频。

## 功能特性

### 🔊 智能音频控制
- **白名单机制**：只有在受信任的 WiFi 网络中才保持正常音量
- **自动静音**：连接到不受信任网络时自动静音
- **耳机检测**：连接耳机时自动禁用音频控制
- **原生音量显示**：音量调整时显示 macOS 原生音量指示器

### 🎧 耳机优先策略
- 检测到耳机连接时，不受 WiFi 网络状态影响
- 耳机断开时，自动恢复基于 WiFi 的音频控制
- 支持多种耳机类型检测（有线、无线、AirPods 等）

### 📡 网络状态监控
- 实时监控 WiFi 网络变化
- 智能状态跟踪，避免重复操作
- 网络切换时显示状态提示

### 😴 系统状态响应
- **睡眠自动静音**：Mac 进入睡眠状态时自动静音
- **唤醒恢复控制**：Mac 唤醒时恢复基于网络和耳机的音频控制
- **屏保自动静音**：Mac 进入屏保时自动静音
- **退出屏保恢复**：Mac 退出屏保时恢复音频控制逻辑
- **锁定自动静音**：Mac 屏幕锁定时自动静音
- **解锁恢复控制**：Mac 屏幕解锁时恢复音频控制逻辑
- **关机前静音**：Mac 关机或注销前自动静音

## 配置说明

### 基本配置

```lua
-- 受信任的 WiFi 网络列表（白名单）
wifiAudio.trustedSSIDs = {
  "Home-WiFi",      -- 家庭网络
  "Office-Secure",  -- 办公室安全网络
  "Cafe-Guest",     -- 常去咖啡厅
}

-- 音频设置
wifiAudio.trustedVolume = 25    -- 受信任网络的音量 (0-100)
wifiAudio.untrustedVolume = 0   -- 不受信任网络的音量 (静音)

-- 耳机检测
wifiAudio.enableHeadphoneDetection = true  -- 启用耳机检测
```

### 自定义配置

1. **添加受信任网络**：
   ```lua
   wifiAudio.trustedSSIDs = {
     "Your-Home-WiFi",
     "Your-Office-WiFi",
     "Friend-House-WiFi",
   }
   ```

2. **调整音量设置**：
   ```lua
   wifiAudio.trustedVolume = 50    -- 提高受信任网络音量
   wifiAudio.untrustedVolume = 5   -- 不完全静音，保留低音量
   ```

3. **禁用耳机检测**：
   ```lua
   wifiAudio.enableHeadphoneDetection = false
   ```

## 工作原理

### 决策逻辑

```
是否连接耳机？
├── 是 → 不控制音量（耳机优先）
└── 否 → 检查 WiFi 网络
    ├── 受信任网络 → 设置正常音量
    └── 不受信任网络 → 静音
```

### 状态转换

1. **网络切换**：
   - 受信任 → 不受信任：自动静音
   - 不受信任 → 受信任：恢复音量
   - 不受信任 → 不受信任：保持静音

2. **耳机状态**：
   - 连接耳机：禁用音频控制
   - 断开耳机：恢复基于网络的控制

3. **系统状态**：
   - 睡眠/屏保/锁定：自动静音
   - 唤醒/退出屏保/解锁：恢复音频控制逻辑
   - 关机/注销：自动静音

### 耳机检测

模块通过检测音频输出设备名称来判断是否连接耳机，支持的关键词包括：
- 英文：headphone, headset, earphone, earbud, airpods, beats
- 中文：耳机, 耳麦, 头戴, 入耳

## 使用场景

### 🏠 家庭环境
- 在家中受信任网络，正常播放音频
- 连接耳机时不受网络影响

### 🏢 办公环境
- 办公室网络设为受信任，可正常使用
- 访客网络自动静音保护隐私

### ☕ 公共场所
- 咖啡厅、图书馆等公共 WiFi 自动静音
- 连接耳机后可正常使用

### ✈️ 出行场景
- 酒店、机场等不受信任网络自动静音
- 保护个人隐私，避免意外播放

### 😴 系统状态场景
- Mac睡眠/屏保/锁定时自动静音，防止意外播放
- 唤醒后/退出屏保/解锁时自动恢复音频控制逻辑
- 关机或注销前自动静音以保护隐私

## 状态提示

模块会在状态变化时显示提示信息：

- `"Connected to trusted network: [网络名]"` - 连接到受信任网络
- `"Connected to untrusted network - Audio muted"` - 连接到不受信任网络并静音
- `"Headphone detected - Audio control disabled"` - 检测到耳机，禁用音频控制
- `"Headphone disconnected - [状态] volume restored"` - 耳机断开，恢复音频控制

## 故障排除

### 常见问题

1. **耳机检测不准确**：
   - 检查音频设备名称是否包含支持的关键词
   - 可以在配置中添加自定义关键词

2. **网络切换延迟**：
   - 正常现象，系统需要时间检测网络变化
   - 通常在 1-3 秒内生效

3. **音量设置无效**：
   - 确保系统音频权限正常
   - 检查是否有其他应用控制音量

### 调试方法

1. **查看当前状态**：
   ```lua
   -- 在 Hammerspoon 控制台执行
   print("Current SSID:", hs.wifi.currentNetwork())
   print("Current Audio Device:", hs.audiodevice.defaultOutputDevice():name())
   ```

2. **手动测试**：
   ```lua
   -- 手动触发检测
   handleAudioControl()
   ```

## 更新日志

### v2.1.0
- 🐛 修复耳机断开后音量控制逻辑错误
- ✨ 新增 macOS 原生音量显示功能
- ✨ 优化耳机状态变化处理逻辑
- ✨ 改进状态跟踪的准确性

### v2.0.0
- ✨ 新增耳机检测功能
- ✨ 优化状态跟踪逻辑
- ✨ 改进用户提示信息
- 🐛 修复重复操作问题

### v1.0.0
- ✨ 基础 WiFi 音频控制
- ✨ 白名单机制
- ✨ 网络状态监控

## 参考资料

- [Hammerspoon 官方文档](https://www.hammerspoon.org/docs/)
- [hs.wifi API](https://www.hammerspoon.org/docs/hs.wifi.html)
- [hs.audiodevice API](https://www.hammerspoon.org/docs/hs.audiodevice.html)
