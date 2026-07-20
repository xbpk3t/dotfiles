--- === ChromeTabLimit Notifications ===
---
--- compact hs.alert；超限时长来自 shared_limit_alerts（与 Claude 对齐）

local notifs = {}

local limits = dofile(hs.configdir .. "/Spoons/shared_limit_alerts.lua")

local COMPACT_STYLE = hs.fnutils.copy(hs.alert.defaultStyle)
COMPACT_STYLE.textSize = 12
COMPACT_STYLE.radius = 8

local function show(text, duration)
  return hs.alert.show(text, COMPACT_STYLE, nil, duration or limits.shortAlertDuration)
end

function notifs.tabLimitExceeded(currentCount, maxCount, excessCount)
  local message = string.format(
    "Chrome 标签页过多！当前: %d 个，限制: %d 个，需关闭: %d 个",
    currentCount,
    maxCount,
    excessCount
  )
  return show(message, limits.limitAlertDuration)
end

function notifs.tabsAutoClosed(closedCount)
  return show(string.format("已自动关闭 %d 个标签页", closedCount))
end

function notifs.tabsCloseFailed()
  return show("无法自动关闭标签页，请手动关闭", limits.limitAlertDuration)
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
