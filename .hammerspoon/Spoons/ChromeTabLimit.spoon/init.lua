--- === ChromeTabLimit ===
---
--- Chrome 标签页数量限制 Spoon
--- 监控 Chrome 标签页数量，超出限制时强制关闭多余标签页
---
--- Download: [https://github.com/your-repo/ChromeTabLimit.spoon](https://github.com/your-repo/ChromeTabLimit.spoon)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "ChromeTabLimit"
obj.version = "1.0.0"
obj.author = "Your Name <your.email@example.com>"
obj.homepage = "https://github.com/your-repo/ChromeTabLimit.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new('ChromeTabLimit')

--- ChromeTabLimit.enabled
--- Variable
--- 是否启用标签页限制功能
obj.enabled = true

--- ChromeTabLimit.maxTabs
--- Variable
--- 最大允许的标签页数量
-- [2026-04-26] 由 25 -> 35
obj.maxTabs = 35

--- ChromeTabLimit.checkInterval
--- Variable
--- 检查间隔（秒）
obj.checkInterval = 30

--- ChromeTabLimit.chromeAppName
--- Variable
--- Chrome 应用程序名称
obj.chromeAppName = "Google Chrome"

--- ChromeTabLimit.autoCloseExcessTabs
--- Variable
--- 是否自动关闭多余的标签页（true: 自动关闭，false: 仅提醒）
obj.autoCloseExcessTabs = false

-- 内部状态
obj.checkTimer = nil
obj.appWatcher = nil


local notifs = dofile(hs.configdir .. "/Spoons/ChromeTabLimit.spoon/notifs.lua")


-- 获取 Chrome 标签页数量
local function getChromeTabCount()
    local script = [[
        tell application "Google Chrome"
            if it is running then
                set tabCount to 0
                set windowList to every window
                repeat with w in windowList
                    set tabCount to tabCount + (number of tabs in w)
                end repeat
                return tabCount
            else
                return 0
            end if
        end tell
    ]]

    local ok, result = hs.osascript.applescript(script)
    if ok then
        local count = tonumber(result) or 0
        obj.logger.d("Chrome tab count: " .. count)
        return count
    else
        obj.logger.w("Error getting Chrome tab count: " .. tostring(result))
        return 0
    end
end

-- 检查 Chrome 是否正在运行
local function isChromeRunning()
    local app = hs.application.get(obj.chromeAppName)
    return app ~= nil and app:isRunning()
end

-- 关闭多余的标签页
local function closeExcessTabs(excessCount)
    local script = string.format([[
        tell application "Google Chrome"
            if it is running then
                set windowList to every window
                set tabsToClose to %d
                set closedCount to 0

                -- 从最后一个窗口的最后一个标签页开始关闭
                repeat with w in reverse of windowList
                    set tabList to every tab in w
                    repeat with t in reverse of tabList
                        if closedCount < tabsToClose then
                            -- 不关闭最后一个标签页（避免关闭窗口）
                            if (count of tabs in w) > 1 then
                                close t
                                set closedCount to closedCount + 1
                            end if
                        end if
                        if closedCount >= tabsToClose then exit repeat
                    end repeat
                    if closedCount >= tabsToClose then exit repeat
                end repeat

                return closedCount
            else
                return 0
            end if
        end tell
    ]], excessCount)

    local ok, result = hs.osascript.applescript(script)
    if ok then
        local closedCount = tonumber(result) or 0
        obj.logger.i("Closed " .. closedCount .. " excess tabs")
        return closedCount
    else
        obj.logger.e("Error closing tabs: " .. tostring(result))
        return 0
    end
end

-- 显示警告并处理超出限制的情况
local function handleTabLimitExceeded(tabCount, excessCount)
    if obj.autoCloseExcessTabs then
        local closedCount = closeExcessTabs(excessCount)
        if closedCount > 0 then
            notifs.tabsAutoClosed(closedCount)
            obj.logger.i("Auto closed " .. closedCount .. " excess tabs")
        else
            notifs.tabsCloseFailed()
            obj.logger.w("Unable to auto-close tabs, showing manual alert")
        end
    else
        notifs.tabLimitExceeded(tabCount, obj.maxTabs, excessCount)
        obj.logger.w("Tab limit exceeded, showing alert")
    end
end

-- 主要检查函数
local function checkTabLimit()
    if not obj.enabled then
        return
    end

    if not isChromeRunning() then
        return
    end

    local tabCount = getChromeTabCount()

    if tabCount > obj.maxTabs then
        local excessCount = tabCount - obj.maxTabs
        handleTabLimitExceeded(tabCount, excessCount)
    end
end

--- ChromeTabLimit:start()
--- Method
--- 启动 ChromeTabLimit
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ChromeTabLimit object
function obj:start()
    if not self.enabled then
        self.logger.i("ChromeTabLimit is disabled, not starting")
        return self
    end

    -- 创建定时器
    self.checkTimer = hs.timer.doEvery(self.checkInterval, checkTabLimit)

    -- 创建应用程序监听器
    self.appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
        if appName == self.chromeAppName then
            if eventType == hs.application.watcher.launched then
                self.logger.i("Chrome launched, starting tab monitoring")
                hs.timer.doAfter(2, checkTabLimit)
            elseif eventType == hs.application.watcher.terminated then
                self.logger.i("Chrome terminated, stopping tab monitoring")
            end
        end
    end)
    self.appWatcher:start()

    -- 立即执行一次检查
    checkTabLimit()

    self.logger.i("ChromeTabLimit started with max tabs: " .. self.maxTabs)
    return self
end

--- ChromeTabLimit:stop()
--- Method
--- 停止 ChromeTabLimit
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ChromeTabLimit object
function obj:stop()
    if self.checkTimer then
        self.checkTimer:stop()
        self.checkTimer = nil
    end

    if self.appWatcher then
        self.appWatcher:stop()
        self.appWatcher = nil
    end

    self.logger.i("ChromeTabLimit stopped")
    return self
end

--- ChromeTabLimit:toggle()
--- Method
--- 切换 ChromeTabLimit 启用状态
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ChromeTabLimit object
function obj:toggle()
    if self.enabled then
        self:stop()
        self.enabled = false
        notifs.disabled()
        self.logger.i("ChromeTabLimit disabled")
    else
        self.enabled = true
        self:start()
        notifs.enabled()
        self.logger.i("ChromeTabLimit enabled")
    end
    return self
end

--- ChromeTabLimit:getStatus()
--- Method
--- 获取当前状态信息
---
--- Parameters:
---  * None
---
--- Returns:
---  * String containing current status
function obj:getStatus()
    local status = string.format("ChromeTabLimit Status:\n启用: %s\n最大标签页: %d\n检查间隔: %d秒\n自动关闭: %s",
                                  self.enabled and "是" or "否",
                                  self.maxTabs,
                                  self.checkInterval,
                                  self.autoCloseExcessTabs and "是" or "否")

    if isChromeRunning() then
        local tabCount = getChromeTabCount()
        status = status .. "\n当前标签页: " .. tabCount
    else
        status = status .. "\nChrome 未运行"
    end

    return status
end

--- ChromeTabLimit:bindHotkeys(mapping)
--- Method
--- 绑定热键
---
--- Parameters:
---  * mapping - 热键映射表
---
--- Returns:
---  * The ChromeTabLimit object
function obj:bindHotkeys(mapping)
    local def = {
        toggle = function()
            self:toggle()
        end,
        check_now = function()
            checkTabLimit()
        end,
        show_status = function()
            notifs.status(self:getStatus())
        end
    }
    hs.spoons.bindHotkeysToSpec(def, mapping)
    return self
end

return obj
