--- === TaskList Notifications ===
---
--- TaskList 专用的通知包装器
--- 基于底层的通知系统，为 TaskList 提供定制的通知功能
---

local notifs = {}

-- 导入底层通知模块
local baseNotifs = dofile(hs.configdir .. "/Spoons/TaskList.spoon/notifs.lua")

-- TaskList 的默认标题
local SPOON_NAME = "TaskList"
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

-- 任务管理相关通知
function notifs.taskAdded(taskName)
    return notifs.sendSuccess("任务已添加: " .. taskName)
end

function notifs.taskCompleted(taskName)
    return notifs.sendSuccess("任务已完成: " .. taskName)
end

function notifs.taskDeleted()
    return notifs.sendInfo("任务已删除")
end

function notifs.taskLimitReached(maxTasks)
    return notifs.sendError("活跃任务数量已达上限 (" .. maxTasks .. ")", 5)
end

function notifs.noCurrentTask()
    return notifs.sendInfo("当前没有任务")
end

-- 倒计时相关通知
function notifs.countdownStarted(minutes)
    return notifs.sendInfo("已启动 " .. minutes .. " 分钟倒计时")
end

function notifs.countdownEnded()
    return notifs.sendSuccess("倒计时结束！任务时间到", 10)
end

function notifs.countdownAutoExtended()
    return notifs.sendInfo("倒计时已自动续期40分钟", 10)
end

function notifs.countdownStatus(status)
    return notifs.sendInfo("倒计时" .. status)
end

-- CronTask 相关通知
function notifs.cronTaskLoaded(newTasksCount)
    if newTasksCount > 0 then
        return notifs.sendSuccess("CronTask 已加载 " .. newTasksCount .. " 个新任务")
    else
        return notifs.sendInfo("重新加载完成，没有新任务")
    end
end

function notifs.cronTaskError(errorMsg)
    return notifs.sendError("CronTask 错误: " .. errorMsg)
end

-- 输入错误通知
function notifs.inputError(message)
    return notifs.sendError("输入错误: " .. message)
end

function notifs.dateFormatError()
    return notifs.sendError("日期格式错误，请使用 YYYY-MM-DD 格式")
end

function notifs.taskNameEmpty()
    return notifs.sendError("任务名称不能为空")
end

-- 导出相关通知
function notifs.exportCompleted(dateLabel, taskCount)
    return notifs.sendSuccess("已导出 " .. (dateLabel or "指定日期") .. " 的 " .. taskCount .. " 个任务到剪贴板", 5)
end

function notifs.exportNoTasks(dateLabel)
    return notifs.sendInfo((dateLabel or "指定日期") .. " 没有已完成的任务")
end

-- 启动状态通知
function notifs.started()
    return notifs.sendSuccess("多任务管理器已启动")
end

-- 获取默认配置
function notifs.getDefaults()
    return baseNotifs.getDefaults()
end

return notifs
