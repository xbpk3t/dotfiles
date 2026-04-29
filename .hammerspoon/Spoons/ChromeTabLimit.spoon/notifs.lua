--- === ChromeTabLimit Notifications ===
---
--- ChromeTabLimit 专用的提示包装器
--- 基于 hs.alert 屏显覆盖层，compact/mini 风格

local notifs = {}

hs.alert.defaultStyle.textSize = 12
hs.alert.defaultStyle.radius = 8

local DEFAULT_DURATION = 3

function notifs.show(text, duration)
    return hs.alert.show(text, duration or DEFAULT_DURATION)
end

function notifs.tabLimitExceeded(currentCount, maxCount, excessCount)
    local message = string.format("Chrome 标签页过多！当前: %d 个，限制: %d 个，需关闭: %d 个",
                                  currentCount, maxCount, excessCount)
    return notifs.show(message, 5)
end

function notifs.tabsAutoClosed(closedCount)
    return notifs.show(string.format("已自动关闭 %d 个标签页", closedCount))
end

function notifs.tabsCloseFailed()
    return notifs.show("无法自动关闭标签页，请手动关闭", 5)
end

function notifs.enabled()
    return notifs.show("ChromeTabLimit 已启用")
end

function notifs.disabled()
    return notifs.show("ChromeTabLimit 已禁用")
end

function notifs.status(statusText)
    return notifs.show("状态信息:\n" .. statusText, 5)
end

return notifs
