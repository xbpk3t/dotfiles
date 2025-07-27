--- === TaskList CronTask ===
---
--- 周期任务解析和过滤模块
---

local cronTask = {}
local spoonPath = hs.configdir .. "/Spoons/TaskList.spoon"
local utils = dofile(spoonPath .. "/utils.lua")
local tasks = dofile(spoonPath .. "/tasks.lua")
local tinyyaml = dofile(spoonPath .. "/tinyyaml.lua")

-- 提取时间数字的正则表达式模式
local function extractTimeNumber(taskType)
    local number = string.match(taskType, "^(%d+)")
    if number then
        return true, tonumber(number)
    end
    return false, 1
end

-- 获取基础任务类型（去掉数字前缀）
local function getBaseType(taskType)
    return string.gsub(taskType, "^%d+", "")
end

-- 判断是否应该显示任务
local function shouldShowTask(taskType, now)
    local isMatched, number = extractTimeNumber(taskType)
    local baseType = getBaseType(taskType)

    -- 获取当前日期信息
    local currentDay = tonumber(os.date("%d", now))
    local currentWeekday = tonumber(os.date("%w", now)) -- 0=Sunday, 1=Monday, ...
    local currentMonth = tonumber(os.date("%m", now))
    local currentYear = tonumber(os.date("%Y", now))

    -- 计算周数（ISO周数）
    local function getWeekOfYear(timestamp)
        return tonumber(os.date("%W", timestamp))
    end

    if baseType == "daily" then
        if not isMatched then
            return true -- 每日任务总是显示
        else
            -- 2daily 等：按天数取模
            return currentDay % number == 0
        end
    elseif baseType == "weekly" then
        -- 周六执行
        local isSaturday = (currentWeekday == 6)
        if not isMatched then
            return isSaturday
        else
            -- 2weekly 等：按周数取模
            local weekOfYear = getWeekOfYear(now)
            return isSaturday and (weekOfYear % number == 0)
        end
    elseif baseType == "monthly" then
        -- 每月1号执行
        local isFirstDay = (currentDay == 1)
        if not isMatched then
            return isFirstDay
        else
            -- 按月数取模
            return isFirstDay and (currentMonth % number == 0)
        end
    elseif baseType == "yearly" then
        -- 每年1月1号执行
        return currentMonth == 1 and currentDay == 1
    else
        return false
    end
end

-- 解析YAML文件
function cronTask.parseCronTaskFile(filePath)
    local file = io.open(filePath, "r")
    if not file then
        hs.logger.new('CronTask'):w("无法打开文件: " .. filePath)
        return {}
    end

    local content = file:read("*all")
    file:close()

    if not content or content == "" then
        hs.logger.new('CronTask'):w("文件为空: " .. filePath)
        return {}
    end

    local success, cronTasks = pcall(tinyyaml.parse, content)
    if not success then
        hs.logger.new('CronTask'):e("解析YAML失败: " .. tostring(cronTasks))
        return {}
    end

    return cronTasks or {}
end

-- 过滤当前应该执行的任务
function cronTask.filterCronTasks(cronTasks)
    local now = os.time()
    local filteredTasks = {}

    for _, cronTaskItem in ipairs(cronTasks) do
        if cronTaskItem.type and cronTaskItem.item then
            if shouldShowTask(cronTaskItem.type, now) then
                for _, taskItem in ipairs(cronTaskItem.item) do
                    if taskItem.task then
                        table.insert(filteredTasks, {
                            type = "@" .. cronTaskItem.type,
                            task = taskItem.task,
                            time = taskItem.time,
                            isAuto = taskItem.isAuto,
                            sub = taskItem.sub
                        })
                    end
                end
            end
        end
    end

    return filteredTasks
end

-- 计算 CronTask 的标准化日期和时间
local function calculateCronTaskDateTime(cronType)
    local now = os.time()
    local baseType = getBaseType(string.gsub(cronType, "^@", ""))

    if baseType == "daily" or string.match(baseType, "daily$") then
        -- daily 类型：使用当天的 00:00:00
        local currentDate = utils.getCurrentDate()
        local year, month, day = currentDate:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
        local dayStart = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 0, min = 0, sec = 0})
        return currentDate, math.floor(dayStart * 1000)
    elseif baseType == "weekly" or string.match(baseType, "weekly$") then
        -- weekly 类型：使用本周六的 00:00:00
        local currentWeekday = tonumber(os.date("%w", now)) -- 0=Sunday, 1=Monday, ..., 6=Saturday
        local daysToSaturday = (6 - currentWeekday) % 7
        local saturday = now + daysToSaturday * 24 * 60 * 60
        local saturdayDate = os.date("%Y-%m-%d", saturday)
        local year, month, day = saturdayDate:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
        local saturdayStart = os.time({year = tonumber(year), month = tonumber(month), day = tonumber(day), hour = 0, min = 0, sec = 0})
        return saturdayDate, math.floor(saturdayStart * 1000)
    else
        -- 其他类型：使用当前日期和时间
        local currentDate = utils.getCurrentDate()
        return currentDate, math.floor(hs.timer.secondsSinceEpoch() * 1000)
    end
end

-- 将过滤后的cron任务转换为TaskList任务格式
function cronTask.convertToTaskListFormat(filteredCronTasks)
    local taskListTasks = {}

    for _, cronTaskRes in ipairs(filteredCronTasks) do
        -- 生成任务名称，包含类型前缀
        local taskName = cronTaskRes.type .. " " .. cronTaskRes.task

        -- 计算标准化的日期和添加时间，确保幂等性
        local taskDate, addTime = calculateCronTaskDateTime(cronTaskRes.type)

        -- 手动创建任务，使用标准化的 addTime
        local newTask = {
            id = utils.generateTaskId(addTime, taskName, taskDate, 1),
            name = taskName,
            date = taskDate,
            addTime = addTime,
            estimatedTime = 1, -- 默认1个E1f
            actualTime = 0,
            isDone = false,
            doneAt = nil,
            startTime = nil
        }

        -- 标记为cron任务，用于识别和去重
        newTask.isCronTask = true
        newTask.cronType = cronTaskRes.type
        newTask.originalTask = cronTaskRes.task

        table.insert(taskListTasks, newTask)
    end

    return taskListTasks
end

-- 检查任务是否已存在（用于去重）
function cronTask.isTaskExists(taskList, cronTask)
    -- 使用 ID 进行精确匹配，确保相同日期的相同任务不重复
    for _, existingTask in ipairs(taskList) do
        if existingTask.isCronTask and existingTask.id == cronTask.id then
            return true
        end
    end

    return false
end

-- 清理过期的cron任务（可选功能）
function cronTask.cleanupExpiredCronTasks(taskList)
    local now = os.time()
    local cleanedTasks = {}

    for _, task in ipairs(taskList) do
        if task.isCronTask then
            -- 检查cron任务是否仍然有效
            local baseType = getBaseType(string.gsub(task.cronType, "^@", ""))
            local taskType = string.gsub(task.cronType, "^@", "")

            if shouldShowTask(taskType, now) then
                table.insert(cleanedTasks, task)
            end
        else
            -- 保留非cron任务
            table.insert(cleanedTasks, task)
        end
    end

    return cleanedTasks
end

-- 主要的加载和集成函数
function cronTask.loadAndIntegrateCronTasks(taskList, cronTaskFilePath)
    -- 解析YAML文件
    local cronTasks = cronTask.parseCronTaskFile(cronTaskFilePath)
    if #cronTasks == 0 then
        return taskList -- 如果没有cron任务，返回原任务列表
    end

    -- 过滤当前应该执行的任务
    local filteredCronTasks = cronTask.filterCronTasks(cronTasks)

    -- 转换为TaskList格式
    local newCronTasks = cronTask.convertToTaskListFormat(filteredCronTasks)

    -- 去重：只添加不存在的任务
    local tasksToAdd = {}
    for _, cronTaskItem in ipairs(newCronTasks) do
        if not cronTask.isTaskExists(taskList, cronTaskItem) then
            table.insert(tasksToAdd, cronTaskItem)
        end
    end

    -- 添加新任务到任务列表
    for _, newTask in ipairs(tasksToAdd) do
        table.insert(taskList, newTask)
    end

    hs.logger.new('CronTask'):i(string.format("加载了 %d 个cron任务，新增 %d 个任务",
        #newCronTasks, #tasksToAdd))

    return taskList
end

return cronTask
