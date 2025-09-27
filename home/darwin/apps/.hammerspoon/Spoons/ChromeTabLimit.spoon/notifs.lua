--- === ChromeTabLimit Notifications ===
---
--- ChromeTabLimit 专用的通知包装器
--- 基于底层的通知系统，为 ChromeTabLimit 提供定制的通知功能
---

local notifs = {}

-- 导入底层通知模块
local baseNotifs = dofile(hs.configdir .. "/Spoons/TaskList.spoon/notifs.lua")

-- ChromeTabLimit 的默认标题
local SPOON_NAME = "ChromeTabLimit"
local DEFAULT_WITHDRAW_AFTER = baseNotifs.getDefaults().withdrawAfter

-- 发送基础通知
function notifs.sendNotification(text, withdrawAfter, soundName)
    return baseNotifs.sendNotification(SPOON_NAME, text, withdrawAfter, soundName)
end

-- 发送默认通知
function notifs.sendDefault(text, soundName)
    return baseNotifs.sendDefaultNotification(SPOON_NAME, text, soundName)
end

-- 发送成功通知
function notifs.sendSuccess(text, withdrawAfter)
    return baseNotifs.sendSuccess(SPOON_NAME, text, withdrawAfter)
end

-- 发送错误通知
function notifs.sendError(text, withdrawAfter)
    return baseNotifs.sendError(SPOON_NAME, text, withdrawAfter)
end

-- 发送信息通知
function notifs.sendInfo(text, withdrawAfter)
    return baseNotifs.sendInfo(SPOON_NAME, text, withdrawAfter)
end

-- 标签页限制相关通知
function notifs.tabLimitExceeded(currentCount, maxCount, excessCount)
    local message = string.format("Chrome 标签页过多！\n当前: %d 个，限制: %d 个\n需要关闭: %d 个标签页",
                                  currentCount, maxCount, excessCount)
    return notifs.sendError(message, 0) -- 无限显示直到解决
end

function notifs.tabsAutoClosed(closedCount)
    local message = string.format("已自动关闭 %d 个标签页", closedCount)
    return notifs.sendSuccess(message)
end

function notifs.tabsCloseFailed()
    return notifs.sendError("无法自动关闭标签页，请手动关闭", 0)
end

-- 启用/禁用状态通知
function notifs.enabled()
    return notifs.sendSuccess("ChromeTabLimit 已启用")
end

function notifs.disabled()
    return notifs.sendInfo("ChromeTabLimit 已禁用")
end

-- 状态信息通知
function notifs.status(statusText)
    return notifs.sendInfo("状态信息:\n" .. statusText, 5)
end

-- 获取默认配置
function notifs.getDefaults()
    return baseNotifs.getDefaults()
end

return notifs
