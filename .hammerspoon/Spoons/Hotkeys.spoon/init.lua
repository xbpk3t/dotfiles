--- === Hotkeys ===
---
--- Alfred CASK workflow 的 Hammerspoon 原生替代
--- 提供 app 启动热键、窗口管理预设、Chrome tab → Markdown link 功能
---
--- Download: [https://github.com/your-repo/Hotkeys.spoon](https://github.com/your-repo/Hotkeys.spoon)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "Hotkeys"
obj.version = "1.0.0"
obj.author = "Your Name <your.email@example.com>"
obj.homepage = "https://github.com/your-repo/Hotkeys.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new("Hotkeys")

local alerts = dofile(hs.configdir .. "/Spoons/shared_alerts.lua")

-- 内部状态：保存 hotkey 引用以便 unbind
obj._hotkeys = {}

-- 配置：集中控制功能开关
obj._config = {
  chrome = {
    enabled = true, -- 设为 false 可禁用所有 Chrome 相关功能
  },
}

-- Chrome 功能内部状态
obj._chrome = {
  tabHistory = {}, -- keyed by windowID, value = previous tab index
  watcher = nil,
}

-- App 启动（⌘1 / ⌘2 / ⌘3 / ⌘0）

local appHotkeys = {
  { key = "1", bundleID = "com.apple.finder", label = "Finder" },
  { key = "2", bundleID = "com.google.Chrome", label = "Chrome" },
  -- { key = "3", bundleID = "com.jetbrains.goland", label = "GoLand" },
  { key = "3", bundleID = "dev.zed.Zed", label = "Zed" },
  { key = "0", bundleID = "com.cmuxterm.app", label = "Cmux" },
}

local function launchApp(bundleID, label)
  return function()
    local ok, err = hs.application.launchOrFocusByBundleID(bundleID)
    if not ok then
      alerts.error("无法启动 " .. label)
      obj.logger.e("launchOrFocus failed for " .. bundleID .. ": " .. tostring(err))
    end
  end
end

-- Chrome tab → Markdown link（⌘⇧D）

local function chromeTabToMarkdownLink()
  if not obj._config.chrome.enabled then
    return
  end

  -- 先激活 Chrome，刷新 AppleScript bridge 状态，避免 stale reply
  hs.application.launchOrFocusByBundleID("com.google.Chrome")

  -- 短暂等待让 AppleScript bridge 跟上
  hs.timer.usleep(200000) -- 200ms

  local ok, result = hs.osascript.applescript([[
    tell application "Google Chrome"
      if it is running then
        set tabTitle to title of active tab of front window
        set tabURL to URL of active tab of front window
        return tabTitle & "\t" & tabURL
      end if
    end tell
  ]])

  if not ok or not result then
    alerts.error("Chrome 未运行或无活动标签页")
    obj.logger.w("Chrome not running or no active tab")
    return
  end

  obj.logger.i("Raw AppleScript result: " .. tostring(result))

  local title, url = result:match("^(.-)\t(.+)$")
  if not title or not url then
    alerts.error("无法获取标签页信息")
    obj.logger.e("Failed to parse Chrome tab info: " .. tostring(result))
    return
  end

  local markdownLink = "[" .. title .. "](" .. url .. ")"
  hs.pasteboard.setContents(markdownLink)
  alerts.success("已复制 Markdown 链接")
  obj.logger.i("Copied markdown link: " .. markdownLink)
end

-- Chrome Recent Tabs（⌘E）
-- 类似 IntelliJ ⌃⇥ 的最近文件切换，作用于 Chrome 的标签页
-- 按 per-window 跟踪：以 window id 为 key 记录前一个活跃 tab 的 index
--
-- 注意事项（Firefox 未来扩展）：
-- Firefox Quantum+ 的 AppleScript 不支持读取 URL/title of active tab，
-- 需通过 Accessibility API 或 WebExtension → WebSocket bridge 实现

local function chromeToggleRecentTab()
  if not obj._config.chrome.enabled then
    return
  end
  -- Guard 1: Chrome 是前台应用（二次防护——hotkey 层已确保仅 Chrome 前台时注册）
  local frontApp = hs.application.frontmostApplication()
  if not frontApp or frontApp:bundleID() ~= "com.google.Chrome" then
    return
  end

  -- Guard 2: Chrome 在运行
  local chrome = hs.application.get("com.google.Chrome")
  if not chrome then
    return
  end

  -- AppleScript：获取窗口 id、当前 tab index、tab 总数
  local ok, result = hs.osascript.applescript([[
    tell application "Google Chrome"
      if it is running then
        set winId to id of front window
        set activeIdx to active tab index of front window
        set tabCount to count of tabs of front window
        return winId & "\t" & activeIdx & "\t" & tabCount
      end if
    end tell
  ]])

  if not ok or not result then
    return
  end

  local winId, activeIdx, tabCount = result:match("^(%-?%d+)\t(%d+)\t(%d+)$")
  if not winId or not activeIdx or not tabCount then
    obj.logger.e("Failed to parse Chrome tab info: " .. tostring(result))
    return
  end

  winId = tonumber(winId)
  activeIdx = tonumber(activeIdx)
  tabCount = tonumber(tabCount)

  -- Guard 3: 至少 2 个 tab 才切换
  if tabCount < 2 then
    return
  end

  -- 查询历史记录
  local prevIdx = obj._chrome.tabHistory[winId]
  local targetIdx

  if prevIdx then
    targetIdx = prevIdx
  else
    -- 首次按或历史丢失：跳到最后一个 tab
    targetIdx = tabCount
    obj.logger.d("Chrome recent tabs: first press, no history, jumping to tab " .. tabCount)
  end

  -- 执行切换
  local setOk, setErr = hs.osascript.applescript(string.format(
    [[
    tell application "Google Chrome"
      set active tab index of front window to %d
    end tell
  ]],
    targetIdx
  ))

  if not setOk then
    -- Tab 已被关闭或索引无效 → 清除该窗口 state，静默 fallback
    obj.logger.w(
      "Chrome recent tabs: failed to set tab "
        .. targetIdx
        .. " (tab may have been closed), resetting history for window "
        .. winId
    )
    obj._chrome.tabHistory[winId] = nil
    return
  end

  -- 更新历史：记录切换前的 index
  obj._chrome.tabHistory[winId] = activeIdx

  obj.logger.i("Chrome recent tabs: " .. activeIdx .. " ↔ " .. targetIdx .. " (window " .. winId .. ")")
end

-- Chrome app watcher: 动态开关 ⌘E 热键 + 清理历史记录
-- 仅在 Chrome 前台时启用 system-level hotkey，避免干扰其他应用
local function chromeWatcherCallback(appName, eventType, app)
  if appName ~= "Google Chrome" then
    return
  end
  if eventType == hs.application.watcher.terminated then
    obj._chrome.tabHistory = {}
    obj.logger.i("Chrome terminated, cleared tab history")
  elseif eventType == hs.application.watcher.activated then
    if obj._hkRecent then
      obj._hkRecent:enable()
      obj.logger.d("⌘E hotkey enabled (Chrome activated)")
    end
  elseif eventType == hs.application.watcher.deactivated then
    if obj._hkRecent then
      obj._hkRecent:disable()
      obj.logger.d("⌘E hotkey disabled (Chrome deactivated)")
    end
  end
end

-- 生命周期

--- Hotkeys:start()
--- Method
--- 启动 Hotkeys，绑定所有热键
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Hotkeys object
function obj:start()
  -- App 启动热键（⌘1-3, ⌘0）
  for _, app in ipairs(appHotkeys) do
    local hk = hs.hotkey.new("cmd", app.key, launchApp(app.bundleID, app.label))
    hk:enable()
    table.insert(self._hotkeys, hk)
  end

  -- Chrome 相关功能（受 _config.chrome.enabled 控制）
  if obj._config.chrome.enabled then
    -- Chrome tab → Markdown link（⌘⇧D）
    local hk = hs.hotkey.new("cmd shift", "d", chromeTabToMarkdownLink)
    hk:enable()
    table.insert(self._hotkeys, hk)

    -- Chrome Recent Tabs（⌘E）
    local hkRecent = hs.hotkey.new("cmd", "e", chromeToggleRecentTab)
    -- 不立即 enable：由 app watcher 根据 Chrome 前台状态动态开关
    table.insert(self._hotkeys, hkRecent)
    obj._hkRecent = hkRecent -- 供 watcher callback 动态 enable/disable

    -- Chrome app watcher：管理 ⌘E 绑定状态 + 清理历史记录
    if obj._chrome.watcher then
      obj._chrome.watcher:stop()
    end
    obj._chrome.watcher = hs.application.watcher.new(chromeWatcherCallback)
    obj._chrome.watcher:start()
  end

  -- 初始状态：若 Chrome 已在前台，立即启用 ⌘E
  if obj._config.chrome.enabled and obj._hkRecent then
    local frontApp = hs.application.frontmostApplication()
    if frontApp and frontApp:bundleID() == "com.google.Chrome" then
      obj._hkRecent:enable()
      obj.logger.d("⌘E hotkey enabled (Chrome already frontmost at start)")
    end
  end

  self.logger.i("Hotkeys started, " .. #self._hotkeys .. " hotkeys bound")
  return self
end

--- Hotkeys:stop()
--- Method
--- 停止 Hotkeys，解绑所有热键
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Hotkeys object
function obj:stop()
  for _, hk in ipairs(self._hotkeys) do
    hk:disable()
  end
  self._hotkeys = {}

  if obj._chrome.watcher then
    obj._chrome.watcher:stop()
    obj._chrome.watcher = nil
  end

  obj._hkRecent = nil
  obj._chrome.tabHistory = {}
  self.logger.i("Hotkeys stopped")
  return self
end

return obj
