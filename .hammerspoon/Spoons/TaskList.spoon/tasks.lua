--- === TaskList Tasks ===
---
--- 核心任务管理功能模块
---

local tasks = {}
local utils = dofile(hs.configdir .. "/Spoons/TaskList.spoon/utils.lua")

-- 根据任务ID查找任务
function tasks.findTaskById(taskList, taskId)
    if not taskId then return nil end
    for i, task in ipairs(taskList) do
        if task.id == taskId then
            return task, i
        end
    end
    return nil, nil
end

-- 任务排序函数 (按日期)
function tasks.sortTasks(taskList)
    table.sort(taskList, function(a, b)
        if a.isDone ~= b.isDone then
            return not a.isDone  -- 未完成的任务排在前面
        end
        return a.date < b.date
    end)
end

-- 获取活跃任务（未完成的任务）
function tasks.getActiveTasks(taskList)
    local activeTasks = {}
    for i, task in ipairs(taskList) do
        if not task.isDone then
            table.insert(activeTasks, {task = task, index = i})
        end
    end
    return activeTasks
end

-- 创建新任务
function tasks.createTask(taskName, dateStr, estimatedTime, review)
    local addTime = math.floor(hs.timer.secondsSinceEpoch() * 1000) -- 任务添加时间（精确到毫秒）
    local newTask = {
        id = utils.generateTaskId(addTime, taskName, dateStr, estimatedTime),
        name = taskName,
        date = dateStr,
        addTime = addTime,
        estimatedTime = estimatedTime,
        actualTime = 0,
        isDone = false,
        doneAt = nil,
        startTime = nil,
        review = review or ""  -- 新增复盘字段，可选
    }
    return newTask
end

-- 启动任务
function tasks.startTask(task)
    if task and not task.startTime then
        task.startTime = os.time()
        return true
    end
    return false
end

-- 停止任务并记录实际时间
function tasks.stopTask(task)
    if task and task.startTime then
        local elapsed = os.time() - task.startTime
        task.actualTime = math.floor(elapsed / 60) -- 转换为分钟
        return true
    end
    return false
end

-- 完成任务
function tasks.completeTask(task)
    if task and not task.isDone then
        task.isDone = true
        -- 修改为包含日期的完整时间格式
        task.doneAt = os.date("%Y-%m-%d %H:%M")
        return true
    end
    return false
end

-- 更新任务实际时间
function tasks.updateTaskActualTime(task)
    if task and task.startTime then
        local elapsed = os.time() - task.startTime
        task.actualTime = math.floor(elapsed / 60) -- 转换为分钟
        return true
    end
    return false
end

return tasks
