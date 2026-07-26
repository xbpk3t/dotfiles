# MicGuard

把系统**默认输入**钉在 Mac 内置麦克风上，避免蓝牙耳机（FreeBuds 等）被 WeType / 会议 App 选成输入后掉进 HFP 通话音质。

## 背景

经典蓝牙耳机不能同时维持高质量 A2DP（听音乐）和麦克风上行。一旦默认输入变成耳机麦，macOS 会切到 HFP：单声道、16 kHz、体感音量异常。

WeType 语音输入需要麦克风，但**不需要**用耳机麦——用 MBA 内置麦即可。MicGuard 不关 WeType，只拦「默认输入 = 耳机」。

## 行为

- 每秒检查一次 `defaultInputDevice`
- 若名称/UID 命中耳机麦特征（FreeBuds / AirPods / headset / `*:input` 等）→ 强制切回 `BuiltInMicrophoneDevice`
- **不改**默认输出、不改音量
- **不用** `hs.audiodevice.watcher`（该 API 全局单回调，已被 AudioControl 占用）

## 配置

```lua
spoon.MicGuard.preferredInputUID = "BuiltInMicrophoneDevice"
spoon.MicGuard.pollInterval = 1.0
spoon.MicGuard.alertOnFix = true
spoon.MicGuard.alertCooldownSeconds = 30
-- 可按需追加被拦截的输入名
table.insert(spoon.MicGuard.blockedInputNameSubstrings, "Sony")
```

## 热路径

```lua
spoon.MicGuard:checkNow()  -- 立刻检查并修复
spoon.MicGuard:status()    -- alert + 日志当前状态
spoon.MicGuard:stop()
spoon.MicGuard:start()
```

## 与 WeType 的关系

| 需求 | 做法 |
|------|------|
| 继续用语音输入 | 保持 WeType 麦克风权限 |
| 听歌保持 A2DP | MicGuard 保证输入不是 FreeBuds |
| 语音实际从哪录 | MacBook 内置麦（桌面场景通常够用） |

若某次你**明确**要用耳机麦通话，先 `spoon.MicGuard:stop()`，打完再 `start()`。
