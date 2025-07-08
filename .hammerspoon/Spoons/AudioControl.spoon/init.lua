--- === AudioControl ===
---
--- 智能音频控制 Spoon
--- 根据 WiFi 网络连接状态和耳机连接状态自动调整系统音量
---
--- Download: [https://github.com/your-repo/AudioControl.spoon](https://github.com/your-repo/AudioControl.spoon)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "AudioControl"
obj.version = "2.1.0"
obj.author = "Your Name <your.email@example.com>"
obj.homepage = "https://github.com/your-repo/AudioControl.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new('AudioControl')

--- AudioControl.trustedSSIDs
--- Variable
--- 受信任的 WiFi 网络列表（白名单）
--- 连接到这些网络时保持正常音量，其他网络时静音
obj.trustedSSIDs = {
  "MUDU",           -- 公司网络
  "Home-WiFi",      -- 家庭网络
  "Cafe-Guest",     -- 常去咖啡厅
}

--- AudioControl.trustedVolume
--- Variable
--- 受信任网络的音量 (0-100)
obj.trustedVolume = 25

--- AudioControl.untrustedVolume
--- Variable
--- 不受信任网络的音量 (静音)
obj.untrustedVolume = 0

--- AudioControl.enableHeadphoneDetection
--- Variable
--- 是否启用耳机检测
obj.enableHeadphoneDetection = true

-- 内部状态
obj.lastSSID = nil
obj.lastHeadphoneState = nil
obj.wifiWatcher = nil

-- 检查当前 SSID 是否在受信任列表中
local function isSSIDTrusted(ssid)
  if not ssid then return false end

  for _, trustedSSID in ipairs(obj.trustedSSIDs) do
    if ssid == trustedSSID then
      return true
    end
  end
  return false
end

-- 检查是否连接了耳机
local function isHeadphoneConnected()
  local currentDevice = hs.audiodevice.defaultOutputDevice()
  if not currentDevice then return false end

  local deviceName = currentDevice:name()
  -- 检查设备名称是否包含耳机相关关键词
  local headphoneKeywords = {
    "headphone", "headset", "earphone", "earbud", "airpods", "beats",
    "耳机", "耳麦", "头戴", "入耳"
  }

  for _, keyword in ipairs(headphoneKeywords) do
    if string.find(string.lower(deviceName), string.lower(keyword)) then
      return true
    end
  end

  return false
end

-- 显示原生音量指示器
local function showVolumeIndicator()
  local device = hs.audiodevice.defaultOutputDevice()
  local currentVolume = device:volume()

  -- 微调音量触发显示，然后恢复
  if currentVolume >= 1 then
    device:setVolume(currentVolume - 1)
    hs.timer.doAfter(0.05, function()
      device:setVolume(currentVolume)
    end)
  else
    device:setVolume(currentVolume + 1)
    hs.timer.doAfter(0.05, function()
      device:setVolume(currentVolume)
    end)
  end
end

-- 设置音频音量
local function setVolume(volume)
  hs.audiodevice.defaultOutputDevice():setVolume(volume)
  -- 显示音量指示器
  hs.timer.doAfter(0.1, showVolumeIndicator)
end

-- 主要逻辑处理函数
local function handleAudioControl()
  local currentSSID = hs.wifi.currentNetwork()
  local headphoneConnected = isHeadphoneConnected()

  -- 检查状态是否发生变化
  local ssidChanged = currentSSID ~= obj.lastSSID
  local headphoneStateChanged = headphoneConnected ~= obj.lastHeadphoneState

  if ssidChanged or headphoneStateChanged then
    local wasTrusted = isSSIDTrusted(obj.lastSSID)
    local isTrusted = isSSIDTrusted(currentSSID)

    -- 处理耳机状态变化
    if headphoneStateChanged then
      if headphoneConnected then
        -- 耳机连接：禁用音频控制
        hs.alert.show("Headphone detected - Audio control disabled")
        obj.logger.i("Headphone connected, disabling audio control")
      else
        -- 耳机断开：重新应用 WiFi 规则
        if isTrusted then
          setVolume(obj.trustedVolume)
          hs.alert.show("Headphone disconnected - Trusted network volume restored")
          obj.logger.i("Headphone disconnected, restored trusted network volume")
        else
          setVolume(obj.untrustedVolume)
          hs.alert.show("Headphone disconnected - Untrusted network muted")
          obj.logger.i("Headphone disconnected, muted for untrusted network")
        end
      end
    end

    -- 处理 WiFi 网络变化（仅在未连接耳机时）
    if ssidChanged and not headphoneConnected then
      if isTrusted and not wasTrusted then
        -- 从不受信任网络切换到受信任网络
        setVolume(obj.trustedVolume)
        hs.alert.show("Connected to trusted network: " .. (currentSSID or "Unknown"))
        obj.logger.i("Connected to trusted network: " .. (currentSSID or "Unknown"))
      elseif not isTrusted and wasTrusted then
        -- 从受信任网络切换到不受信任网络
        setVolume(obj.untrustedVolume)
        hs.alert.show("Connected to untrusted network - Audio muted")
        obj.logger.i("Connected to untrusted network, audio muted")
      elseif not isTrusted and not wasTrusted then
        -- 在不受信任网络之间切换，确保保持静音
        setVolume(obj.untrustedVolume)
        obj.logger.i("Switched between untrusted networks, maintaining mute")
      end
    end

    -- 更新状态
    obj.lastSSID = currentSSID
    obj.lastHeadphoneState = headphoneConnected
  end
end

--- AudioControl:start()
--- Method
--- 启动 AudioControl
---
--- Parameters:
---  * None
---
--- Returns:
---  * The AudioControl object
function obj:start()
  -- 创建 WiFi 监听器
  self.wifiWatcher = hs.wifi.watcher.new(handleAudioControl)
  self.wifiWatcher:start()

  -- 创建音频设备监听器
  local function audioDeviceCallback(event)
    if event and (string.find(event, "dOut") or string.find(event, "dev")) then
      -- 延迟一点执行，确保设备状态已更新
      hs.timer.doAfter(0.5, handleAudioControl)
    end
  end

  hs.audiodevice.watcher.setCallback(audioDeviceCallback)
  hs.audiodevice.watcher.start()

  -- 设置初始状态
  handleAudioControl()

  self.logger.i("AudioControl started")
  return self
end

--- AudioControl:stop()
--- Method
--- 停止 AudioControl
---
--- Parameters:
---  * None
---
--- Returns:
---  * The AudioControl object
function obj:stop()
  if self.wifiWatcher then
    self.wifiWatcher:stop()
    self.wifiWatcher = nil
  end

  hs.audiodevice.watcher.stop()

  self.logger.i("AudioControl stopped")
  return self
end

--- AudioControl:bindHotkeys(mapping)
--- Method
--- 绑定热键
---
--- Parameters:
---  * mapping - 热键映射表
---
--- Returns:
---  * The AudioControl object
function obj:bindHotkeys(mapping)
  local def = {
    toggle_mute = function()
      local device = hs.audiodevice.defaultOutputDevice()
      device:setOutputMuted(not device:outputMuted())
      showVolumeIndicator()
    end,
    show_status = function()
      local currentSSID = hs.wifi.currentNetwork()
      local headphoneConnected = isHeadphoneConnected()
      local status = string.format("WiFi: %s | Headphone: %s",
        currentSSID or "None",
        headphoneConnected and "Connected" or "Disconnected")
      hs.alert.show(status)
    end
  }
  hs.spoons.bindHotkeysToSpec(def, mapping)
  return self
end

return obj
