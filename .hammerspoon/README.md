# Hammerspoon 配置

这是一个完整的 Hammerspoon 配置，包含多个实用的 Spoons，提供音频控制、蓝牙管理等功能。

## 📁 目录结构

```
.hammerspoon/
├── init.lua                    # 主配置文件
├── tasks_data.json            # 任务数据文件
├── Spoons/                    # Spoons 目录
│   ├── AudioControl.spoon/    # 音频控制 Spoon
│   │   ├── init.lua
│   │   └── README.md
│   └── BluetoothManager.spoon/ # 蓝牙管理 Spoon
│       ├── init.lua
│       └── README.md
└── README.md                  # 本文件
```

## 🚀 快速开始

### 1. 安装依赖

```bash
# 安装 Hammerspoon
brew install --cask hammerspoon

# 安装 blueutil（蓝牙管理需要）
brew install blueutil
```

### 2. 配置权限

在 **系统偏好设置 → 安全性与隐私 → 辅助功能** 中添加 Hammerspoon。

### 3. 加载配置

将此配置目录复制到 `~/.hammerspoon/`，然后重新加载 Hammerspoon 配置。

## 📦 包含的 Spoons

### 🔊 AudioControl
智能音频控制，根据 WiFi 网络和耳机连接状态自动调整音量。

**功能特性**：
- WiFi 网络白名单机制
- 耳机检测和优先级控制
- macOS 原生音量显示
- 智能状态跟踪

**热键**：
- `Cmd+Alt+M` - 切换静音
- `Cmd+Alt+S` - 显示状态

### 📱 BluetoothManager
完整的蓝牙设备管理功能。

**功能特性**：
- 蓝牙电源控制
- 设备连接/断开
- 设备信息查询
- 设备列表显示

**热键**：
- `Cmd+Alt+B` - 切换蓝牙电源
- `Cmd+Alt+Shift+B` - 连接默认设备
- `Cmd+Alt+I` - 显示蓝牙状态

## ⚙️ 配置说明

### 音频控制配置

```lua
-- 受信任的 WiFi 网络
spoon.AudioControl.trustedSSIDs = {
  "MUDU",           -- 公司网络
  "Home-WiFi",      -- 家庭网络
  "Cafe-Guest",     -- 常去咖啡厅
}

-- 音量设置
spoon.AudioControl.trustedVolume = 25    -- 受信任网络音量
spoon.AudioControl.untrustedVolume = 0   -- 不受信任网络音量
```

### 蓝牙管理配置

```lua
-- 默认蓝牙设备 ID
spoon.BluetoothManager.defaultDeviceID = "your-device-id"

-- blueutil 路径（如果不在默认位置）
spoon.BluetoothManager.blueutil_path = "/opt/homebrew/bin/blueutil"
```

## 🔧 自定义热键

你可以在 `init.lua` 中修改热键绑定：

```lua
-- 音频控制热键
spoon.AudioControl:bindHotkeys({
    toggle_mute = {{"cmd", "alt"}, "m"},
    show_status = {{"cmd", "alt"}, "s"}
})

-- 蓝牙管理热键
spoon.BluetoothManager:bindHotkeys({
    toggle_power = {{"cmd", "alt"}, "b"},
    connect_default = {{"cmd", "alt", "shift"}, "b"},
    show_status = {{"cmd", "alt"}, "i"}
})

```

## 🛠️ 系统功能

### 健康提醒
每 40 分钟提醒站起来活动一下。

### 安全关机
每天 22:00 检查系统状态，在满足条件时自动关机：
- 无下载任务运行
- 用户空闲超过 10 分钟

## 📚 详细文档

每个 Spoon 都有详细的 README 文档：

## 🐛 故障排除

### 常见问题

1. **配置加载失败**
   - 检查 Hammerspoon 是否有辅助功能权限
   - 查看 Hammerspoon 控制台的错误信息

2. **蓝牙功能不工作**
   - 确保已安装 blueutil：`brew install blueutil`
   - 检查 blueutil 路径是否正确

3. **音频控制不生效**
   - 检查 WiFi 网络名称是否正确配置
   - 确认耳机检测关键词是否匹配

### 调试方法

```lua
-- 设置调试日志级别
hs.logger.setGlobalLogLevel("debug")

-- 查看特定 Spoon 的日志
spoon.AudioControl.logger.setLogLevel("debug")
```

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🔗 相关链接

- [Hammerspoon 官网](https://www.hammerspoon.org/)
- [Hammerspoon API 文档](https://www.hammerspoon.org/docs/)
- [Spoons 官方仓库](https://github.com/Hammerspoon/Spoons)
