--- === Base Notifications ===
---
--- 底层通知系统处理模块
--- 提供基础的通知发送功能，所有 Spoon 都应通过各自的通知包装器调用此模块
---

local notifs = {}

-- 默认配置
local DEFAULT_WITHDRAW_AFTER = 3
local SUCCESS_SOUND = "Glass"
local ERROR_SOUND = "Basso"

-- 私有函数：核心通知发送逻辑
local function _sendNotification(title, text, withdrawAfter, soundName)
    withdrawAfter = withdrawAfter or DEFAULT_WITHDRAW_AFTER

    local notification = hs.notify.new({
        title = title or "通知",
        informativeText = text or "",
        withdrawAfter = withdrawAfter
    })

    if soundName then
        notification:soundName(soundName)
    end

    local success = pcall(function()
        notification:send()
    end)

    if not success then
        print("通知发送失败: " .. title .. " - " .. text)
        -- 如果通知失败，至少在控制台输出
        print("📢 " .. title .. ": " .. text)
    end

    return success
end

-- 公共 API：发送基础通知（保留向后兼容性）
function notifs.sendNotification(title, text, withdrawAfter, soundName)
    return _sendNotification(title, text, withdrawAfter, soundName)
end

-- 发送默认通知（使用默认的 withdrawAfter）
function notifs.sendDefaultNotification(title, text, soundName)
    return _sendNotification(title, text, DEFAULT_WITHDRAW_AFTER, soundName)
end

-- 发送成功通知
function notifs.sendSuccess(title, text, withdrawAfter)
    return _sendNotification(title, text, withdrawAfter, SUCCESS_SOUND)
end

-- 发送错误通知
function notifs.sendError(title, text, withdrawAfter)
    return _sendNotification(title, text, withdrawAfter, ERROR_SOUND)
end

-- 发送信息通知（无声音）
function notifs.sendInfo(title, text, withdrawAfter)
    return _sendNotification(title, text, withdrawAfter, nil)
end

-- 获取默认配置（供其他模块使用）
function notifs.getDefaults()
    return {
        withdrawAfter = DEFAULT_WITHDRAW_AFTER,
        successSound = SUCCESS_SOUND,
        errorSound = ERROR_SOUND
    }
end

return notifs
