--- === TaskList Countdown ===
---
--- 倒计时和计时器功能模块
---

local countdown = {}
local notifications = dofile(hs.configdir .. "/Spoons/TaskList.spoon/notifications.lua")

-- 倒计时状态变量
local countdownTimer = nil
local remainingSeconds = 0
local isPaused = false
local taskCountdowns = {}

-- 获取倒计时状态
function countdown.getCountdownState()
    return {
        timer = countdownTimer,
        remainingSeconds = remainingSeconds,
        isPaused = isPaused,
        taskCountdowns = taskCountdowns
    }
end

-- 设置倒计时状态
function countdown.setCountdownState(state)
    countdownTimer = state.timer
    remainingSeconds = state.remainingSeconds or 0
    isPaused = state.isPaused or false
    taskCountdowns = state.taskCountdowns or {}
end

-- 计算当前任务应该启动的倒计时时间
function countdown.calculateCountdownTime(task)
    if not task or not task.startTime then
        return task.estimatedTime * 40 -- 如果没有开始时间，返回完整的预计时间
    end

    local elapsed = os.time() - task.startTime
    local elapsedMinutes = math.floor(elapsed / 60)
    local plannedMinutes = task.estimatedTime * 40

    if elapsedMinutes < plannedMinutes then
        -- AD < PD: countdown = PD - AD
        return plannedMinutes - elapsedMinutes
    else
        -- AD >= PD: 自动续期，重置为一个E1f (40分钟)
        return 40
    end
end

-- 启动倒计时
function countdown.startCountdown(minutes, currentTaskId, updateMenubarCallback)
    if countdownTimer and countdownTimer:running() then
        notifications.sendNotification("倒计时提醒", "倒计时已在运行中", 3)
        return
    end

    remainingSeconds = minutes * 60
    isPaused = false

    -- 创建每秒更新的计时器
    countdownTimer = hs.timer.doEvery(1, function()
        if not isPaused then
            remainingSeconds = remainingSeconds - 1

            -- 保存当前任务的剩余时间
            if currentTaskId then
                taskCountdowns[currentTaskId] = remainingSeconds
            end

            if updateMenubarCallback then
                updateMenubarCallback()
            end

            if remainingSeconds <= 0 then
                -- 倒计时结束，自动续期40分钟
                remainingSeconds = 40 * 60
                if currentTaskId then
                    taskCountdowns[currentTaskId] = remainingSeconds
                end

                notifications.sendNotification("⏰ 倒计时结束", "任务时间到！自动续期40分钟", 10, "Glass")

                if updateMenubarCallback then
                    updateMenubarCallback()
                end
            end
        end
    end)

    notifications.sendNotification("倒计时启动", "已启动 " .. minutes .. " 分钟倒计时", 3)
end

-- 停止倒计时
function countdown.stopCountdown(currentTaskId)
    -- 保存当前任务的剩余时间
    if currentTaskId and remainingSeconds > 0 then
        taskCountdowns[currentTaskId] = remainingSeconds
    end

    if countdownTimer then
        countdownTimer:stop()
        countdownTimer = nil
    end
    remainingSeconds = 0
    isPaused = false
end

-- 暂停/恢复倒计时
function countdown.toggleCountdown()
    if countdownTimer and countdownTimer:running() then
        isPaused = not isPaused
        local status = isPaused and "暂停" or "恢复"
        notifications.sendNotification("倒计时" .. status, "倒计时已" .. status, 2)
        return true
    end
    return false
end

-- 恢复任务倒计时
function countdown.resumeTaskCountdown(taskId, updateMenubarCallback)
    if taskCountdowns[taskId] and taskCountdowns[taskId] > 0 then
        -- 直接使用保存的剩余秒数
        remainingSeconds = taskCountdowns[taskId]
        isPaused = false

        -- 创建倒计时器
        countdownTimer = hs.timer.doEvery(1, function()
            if not isPaused then
                remainingSeconds = remainingSeconds - 1

                -- 保存当前任务的剩余时间
                if taskId then
                    taskCountdowns[taskId] = remainingSeconds
                end

                if updateMenubarCallback then
                    updateMenubarCallback()
                end

                if remainingSeconds <= 0 then
                    -- 倒计时结束，自动续期40分钟
                    remainingSeconds = 40 * 60
                    if taskId then
                        taskCountdowns[taskId] = remainingSeconds
                    end

                    notifications.sendNotification("⏰ 倒计时结束", "任务时间到！自动续期40分钟", 10, "Glass")

                    if updateMenubarCallback then
                        updateMenubarCallback()
                    end
                end
            end
        end)

        local minutes = math.floor(remainingSeconds / 60)
        local seconds = remainingSeconds % 60
        return minutes, seconds
    end
    return nil, nil
end

return countdown
