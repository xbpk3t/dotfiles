-- **************************************************
-- WiFi 音频控制模块
-- 连接到指定 Wi-Fi 时自动调整音频设置
-- @ref [dotfiles/hammerspoon/wifi.lua at master · peterpme/dotfiles](https://github.com/peterpme/dotfiles/blob/master/hammerspoon/wifi.lua)
-- **************************************************

local wifiAudio = {}

-- --------------------------------------------------
-- 配置区域
-- --------------------------------------------------

-- 定义受信任的 WiFi 网络列表（白名单）
-- 连接到这些网络时保持正常音量，其他网络时静音
wifiAudio.trustedSSIDs = {
  "MUDU",           -- 公司网络
  "Home-WiFi",      -- 家庭网络
  "Cafe-Guest",     -- 常去咖啡厅
}

-- 音频设置
wifiAudio.trustedVolume = 25  -- 受信任网络的音量 (0-100)
wifiAudio.untrustedVolume = 0 -- 不受信任网络的音量 (静音)

-- 耳机检测设置
wifiAudio.enableHeadphoneDetection = true -- 是否启用耳机检测

-- --------------------------------------------------
-- 内部状态
-- --------------------------------------------------
wifiAudio.lastSSID = nil -- 上次连接的网络
wifiAudio.lastHeadphoneState = nil -- 上次耳机连接状态

-- --------------------------------------------------
-- 辅助函数
-- --------------------------------------------------

-- 检查当前 SSID 是否在受信任列表中
local function isSSIDTrusted(ssid)
  if not ssid then return false end

  for _, trustedSSID in ipairs(wifiAudio.trustedSSIDs) do
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
  -- 方法：临时微调音量来触发系统音量显示
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

-- --------------------------------------------------
-- 主要逻辑
-- --------------------------------------------------

local function handleAudioControl()
  local currentSSID = hs.wifi.currentNetwork()
  local headphoneConnected = isHeadphoneConnected()

  -- 检查状态是否发生变化
  local ssidChanged = currentSSID ~= wifiAudio.lastSSID
  local headphoneStateChanged = headphoneConnected ~= wifiAudio.lastHeadphoneState

  if ssidChanged or headphoneStateChanged then
    local wasTrusted = isSSIDTrusted(wifiAudio.lastSSID)
    local isTrusted = isSSIDTrusted(currentSSID)

    -- 处理耳机状态变化
    if headphoneStateChanged then
      if headphoneConnected then
        -- 耳机连接：禁用音频控制
        hs.alert.show("Headphone detected - Audio control disabled")
      else
        -- 耳机断开：重新应用 WiFi 规则
        if isTrusted then
          setVolume(wifiAudio.trustedVolume)
          hs.alert.show("Headphone disconnected - Trusted network volume restored")
        else
          setVolume(wifiAudio.untrustedVolume)
          hs.alert.show("Headphone disconnected - Untrusted network muted")
        end
      end
    end

    -- 处理 WiFi 网络变化（仅在未连接耳机时）
    if ssidChanged and not headphoneConnected then
      if isTrusted and not wasTrusted then
        -- 从不受信任网络切换到受信任网络
        setVolume(wifiAudio.trustedVolume)
        hs.alert.show("Connected to trusted network: " .. (currentSSID or "Unknown"))
      elseif not isTrusted and wasTrusted then
        -- 从受信任网络切换到不受信任网络
        setVolume(wifiAudio.untrustedVolume)
        hs.alert.show("Connected to untrusted network - Audio muted")
      elseif not isTrusted and not wasTrusted then
        -- 在不受信任网络之间切换，确保保持静音
        setVolume(wifiAudio.untrustedVolume)
      end
    end

    -- 更新状态
    wifiAudio.lastSSID = currentSSID
    wifiAudio.lastHeadphoneState = headphoneConnected
  end
end

-- --------------------------------------------------
-- 初始化
-- --------------------------------------------------

-- 创建 WiFi 监听器
wifiAudio.wifiWatcher = hs.wifi.watcher.new(handleAudioControl)
wifiAudio.wifiWatcher:start()

-- 创建音频设备监听器（监听耳机连接/断开）
-- 注意：音频设备监听器会接收一个事件类型参数
local function audioDeviceCallback(event)
  -- 只在设备变化时触发音频控制检查
  if event and (string.find(event, "dOut") or string.find(event, "dev")) then
    -- 延迟一点执行，确保设备状态已更新
    hs.timer.doAfter(0.5, handleAudioControl)
  end
end

hs.audiodevice.watcher.setCallback(audioDeviceCallback)
hs.audiodevice.watcher.start()

-- 设置初始状态
handleAudioControl()

return wifiAudio
