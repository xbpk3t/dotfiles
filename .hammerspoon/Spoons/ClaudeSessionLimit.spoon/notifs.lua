--- === ClaudeSessionLimit Notifications ===
---
--- compact hs.alert（通过 shared_alerts）；超限时长来自 shared_limit_alerts

local notifs = {}
local alerts = dofile(hs.configdir .. "/Spoons/shared_alerts.lua")
local limits = dofile(hs.configdir .. "/Spoons/shared_limit_alerts.lua")

local function show(text, duration)
  return alerts.show(text, duration or limits.shortAlertDuration)
end

function notifs.sessionLimitExceeded(currentCount, maxCount, excessCount)
  return alerts.error(
    string.format(
      "Claude session 过多！当前: %d 个，限制: %d 个，需关闭: %d 个",
      currentCount,
      maxCount,
      excessCount
    ),
    limits.limitAlertDuration
  )
end

function notifs.enabled()
  return show("ClaudeSessionLimit 已启用")
end

function notifs.disabled()
  return show("ClaudeSessionLimit 已禁用")
end

function notifs.status(statusText)
  return show("状态信息:\n" .. statusText, limits.limitAlertDuration)
end

return notifs
