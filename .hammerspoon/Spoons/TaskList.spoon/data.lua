--- === TaskList Data ===
---
--- 数据持久化和任务数据管理模块
---

local data = {}
local utils = dofile(hs.configdir .. "/Spoons/TaskList.spoon/utils.lua")

-- 数据持久化文件路径
local dataFile = hs.configdir .. "/tasks_data.json"

-- 加载任务数据
function data.loadTasks()
    local tasks = {}
    local currentTaskId = nil

    local file = io.open(dataFile, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local success, data_content = pcall(hs.json.decode, content)
        if success and data_content then
            tasks = data_content.tasks or {}
            -- 兼容旧数据：如果保存的是索引，转换为ID
            if data_content.currentTaskIndex and type(data_content.currentTaskIndex) == "number" and tasks[data_content.currentTaskIndex] then
                currentTaskId = tasks[data_content.currentTaskIndex].id
            else
                currentTaskId = data_content.currentTaskId
            end
            -- 兼容旧数据，为没有新字段的任务添加默认值
            for i, task in ipairs(tasks) do
                if type(task) == "string" then
                    local defaultDate = utils.getCurrentDate()
                    local addTime = math.floor(hs.timer.secondsSinceEpoch() * 1000) -- 为旧任务生成添加时间
                    tasks[i] = {
                        id = utils.generateTaskId(addTime, task, defaultDate, 1),
                        name = task,
                        date = defaultDate,
                        addTime = addTime,
                        estimatedTime = 1, -- 默认1个E1f
                        actualTime = 0,
                        isDone = false,
                        doneAt = nil,
                        startTime = nil
                    }
                else
                    -- 为旧任务添加 addTime 字段
                    task.addTime = task.addTime or math.floor(hs.timer.secondsSinceEpoch() * 1000)
                    task.id = task.id or utils.generateTaskId(task.addTime, task.name or "unknown", task.date or utils.getCurrentDate(), task.estimatedTime or 1)
                    task.date = task.date or utils.getCurrentDate()
                    task.estimatedTime = task.estimatedTime or 1
                    task.actualTime = task.actualTime or 0
                    task.isDone = task.isDone or false
                    task.doneAt = task.doneAt or task.deletedAt or nil
                    task.startTime = task.startTime or nil
                end
            end
        end
    end

    return tasks, currentTaskId
end

-- 保存任务数据
function data.saveTasks(tasks, currentTaskId)
    -- 深拷贝任务列表并清理任务名称
    local cleanedTasks = {}
    for i, task in ipairs(tasks) do
        local cleanedTask = {}
        for key, value in pairs(task) do
            if key == "name" then
                cleanedTask[key] = utils.sanitizeTaskName(value)
            else
                cleanedTask[key] = value
            end
        end
        cleanedTasks[i] = cleanedTask
    end

    local data_content = {
        tasks = cleanedTasks,
        currentTaskId = currentTaskId
    }
    local file = io.open(dataFile, "w")
    if file then
        file:write(hs.json.encode(data_content))
        file:close()
    end
end

return data
