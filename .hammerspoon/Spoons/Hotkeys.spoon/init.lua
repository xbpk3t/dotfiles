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

-- 内部状态：保存 hotkey 引用以便 unbind
obj._hotkeys = {}

-- ========================================
-- App 启动（⌘1 / ⌘2 / ⌘3 / ⌘0）
-- ========================================

local appHotkeys = {
  { key = "1", bundleID = "com.apple.finder", label = "Finder" },
  { key = "2", bundleID = "com.google.Chrome", label = "Chrome" },
  { key = "3", bundleID = "com.jetbrains.goland", label = "GoLand" },
  { key = "0", bundleID = "com.cmuxterm.app", label = "Cmux" },
  -- { key = "0", bundleID = "dev.zed.Zed",          label = "Zed" },
}

local function launchApp(bundleID, label)
  return function()
    local ok, err = hs.application.launchOrFocusByBundleID(bundleID)
    if not ok then
      hs.alert.show("无法启动 " .. label)
      obj.logger.e("launchOrFocus failed for " .. bundleID .. ": " .. tostring(err))
    end
  end
end

-- ========================================
-- 窗口管理（⌘⌥[ / ⌘⌥] / ⌘↩）
-- ========================================

local function moveWindowToUnit(rect)
  return function()
    local win = hs.window.focusedWindow()
    if win then
      win:moveToUnit(rect)
    end
  end
end

local function maximizeWindow()
  return function()
    local win = hs.window.focusedWindow()
    if win then
      win:maximize()
    end
  end
end

-- ========================================
-- Chrome tab → Markdown link（⌘⇧D）
-- ========================================

local function chromeTabToMarkdownLink()
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
    hs.alert.show("Chrome 未运行或无活动标签页")
    obj.logger.w("Chrome not running or no active tab")
    return
  end

  local title, url = result:match("^(.-)\t(.+)$")
  if not title or not url then
    hs.alert.show("无法获取标签页信息")
    obj.logger.e("Failed to parse Chrome tab info: " .. tostring(result))
    return
  end

  local markdownLink = "[" .. title .. "](" .. url .. ")"
  hs.pasteboard.setContents(markdownLink)
  hs.alert.show("已复制 Markdown 链接")
  obj.logger.i("Copied markdown link: " .. markdownLink)
end

-- ========================================
-- 生命周期
-- ========================================

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
    table.insert(self._hotkeys, hs.hotkey.new("cmd", app.key, launchApp(app.bundleID, app.label)))
  end

  -- 窗口管理热键
  table.insert(self._hotkeys, hs.hotkey.new("cmd", "return", maximizeWindow()))
  table.insert(self._hotkeys, hs.hotkey.new("cmd alt", "[", moveWindowToUnit({ x = 0, y = 0, w = 0.5, h = 1 })))
  table.insert(self._hotkeys, hs.hotkey.new("cmd alt", "]", moveWindowToUnit({ x = 0.5, y = 0, w = 0.5, h = 1 })))

  -- Chrome tab → Markdown link
  table.insert(self._hotkeys, hs.hotkey.new("cmd shift", "d", chromeTabToMarkdownLink))

  -- 启用所有热键
  for _, hk in ipairs(self._hotkeys) do
    hk:enable()
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
  self.logger.i("Hotkeys stopped")
  return self
end

return obj
