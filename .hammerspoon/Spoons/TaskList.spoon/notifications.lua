--- === TaskList Notifications ===
---
--- 通知系统处理模块
---

local notifications = {}

-- 安全的通知发送函数
function notifications.sendNotification(title, text, withdrawAfter, soundName)
    withdrawAfter = withdrawAfter or 3

    local notification = hs.notify.new({
        title = title or "任务管理器",
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

return notifications
