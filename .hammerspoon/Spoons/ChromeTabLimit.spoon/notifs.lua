--- === ChromeTabLimit Notifications ===
---
--- compact hs.alert（通过 shared_alerts）；超限时长来自 shared_limit_alerts

local notifs = {}
local alerts = dofile(hs.configdir .. "/Spoons/shared_alerts.lua")
local limits = dofile(hs.configdir .. "/Spoons/shared_limit_alerts.lua")

local function show(text, duration)
  return alerts.show(text, duration or limits.shortAlertDuration)
end

function notifs.tabLimitExceeded(currentCount, maxCount, excessCount)
  local message = string.format(
    "Chrome 标签页过多！当前: %d 个，限制: %d 个，需关闭: %d 个",
    currentCount,
    maxCount,
    excessCount
  )
  return alerts.error(message, limits.limitAlertDuration)
end

function notifs.tabsAutoClosed(closedCount)
  return show(string.format("已自动关闭 %d 个标签页", closedCount))
end

function notifs.tabsCloseFailed()
  return alerts.error("无法自动关闭标签页，请手动关闭", limits.limitAlertDuration)
end

function notifs.enabled()
  return show("ChromeTabLimit 已启用")
end

function notifs.disabled()
  return show("ChromeTabLimit 已禁用")
end

function notifs.status(statusText)
  return show("状态信息:\n" .. statusText, limits.limitAlertDuration)
end

return notifs
