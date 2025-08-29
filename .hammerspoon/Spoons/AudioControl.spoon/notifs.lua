--- === AudioControl notifs ===
---
--- AudioControl 专用的通知包装器
--- 基于底层的通知系统，为 AudioControl 提供定制的通知功能
---

local notifs = {}

-- 导入底层通知模块
local baseNotifs = dofile(hs.configdir .. "/Spoons/TaskList.spoon/notifs.lua")

-- AudioControl 的默认标题
local SPOON_NAME = "AudioControl"
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

-- WiFi 相关通知
function notifs.wifiConnected(networkName)
    return notifs.sendInfo("已连接到受信任网络: " .. (networkName or "Unknown"))
end

function notifs.wifiDisconnected(networkName)
    return notifs.sendInfo("已断开连接: " .. (networkName or "Unknown"))
end

function notifs.trustedNetworkActivated()
    return notifs.sendSuccess("受信任网络规则已激活")
end

function notifs.untrustedNetworkMuted()
    return notifs.sendError("不受信任网络 - 音量已静音")
end

-- 耳机相关通知
function notifs.headphoneConnected()
    return notifs.sendInfo("耳机已连接，音频控制已禁用")
end

function notifs.headphoneDisconnected()
    return notifs.sendInfo("耳机已断开，音频控制已重新启用")
end

-- 状态通知
function notifs.statusInfo(statusText)
    return notifs.sendInfo("状态: " .. statusText, 5)
end

-- 获取默认配置
function notifs.getDefaults()
    return baseNotifs.getDefaults()
end

return notifs
