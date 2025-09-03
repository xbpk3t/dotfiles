--- === TaskList Export ===
---
--- 任务导出功能模块
---

local export = {}
local utils = dofile(hs.configdir .. "/Spoons/TaskList.spoon/utils.lua")
local scoring = dofile(hs.configdir .. "/Spoons/TaskList.spoon/scoring.lua")
local notifs = dofile(hs.configdir .. "/Spoons/TaskList.spoon/tasklist_notifs.lua")

-- 配置不导出的 CronTask 类型
local EXCLUDED_CRON_TYPES = {
    "daily",
    "2daily",
    "weekly",
    "2weekly",
    "4weekly",
    "yearly"
    -- 可以根据需要添加更多类型
}

-- 检查任务是否应该被排除在导出之外
local function shouldExcludeFromExport(task)
    if task.isCronTask and task.cronType then
        -- 移除 @ 前缀进行比较
        local cleanCronType = task.cronType:gsub("^@", "")
        for _, excludedType in ipairs(EXCLUDED_CRON_TYPES) do
            if cleanCronType == excludedType then
                return true
            end
        end
    end
    return false
end

-- 通用任务排序函数
local function sortTasksByCompletionTime(tasks)
    table.sort(tasks, function(a, b)
        local timeA = a.doneAt or "0000-00-00 00:00"
        local timeB = b.doneAt or "0000-00-00 00:00"
        return timeA < timeB
    end)
    return tasks
end

-- 生成单个任务的YAML字符串
local function generateTaskYaml(task, indent)
    indent = indent or "        "
    local yaml = indent .. "- name: " .. utils.sanitizeString(task.name) .. "\n"
    if task.doneAt then
        yaml = yaml .. indent .. "  doneAt: " .. task.doneAt .. "\n"
    end
    if task.estimatedTime and task.estimatedTime > 0 then
        yaml = yaml .. indent .. "  PD: " .. (task.estimatedTime * 40) .. "min\n"
    end
    if task.actualTime and task.actualTime > 0 then
        yaml = yaml .. indent .. "  AD: " .. task.actualTime .. "min\n"
    end
    local score = scoring.calculateScore(task)
    if score > 0 then
        yaml = yaml .. indent .. "  score: " .. score .. "\n"
    end
    if task.review and task.review ~= "" then
        -- 处理多行 review，确保 YAML 格式正确
        local reviewLines = {}
        for line in task.review:gmatch("[^\r\n]+") do
            table.insert(reviewLines, line)
        end
        if #reviewLines > 0 then
            if #reviewLines == 1 then
                -- 单行 review
                yaml = yaml .. indent .. "  review: " .. utils.sanitizeString(reviewLines[1]) .. "\n"
            else
                -- 多行 review
                yaml = yaml .. indent .. "  review: |\n"
                for _, line in ipairs(reviewLines) do
                    yaml = yaml .. indent .. "    " .. utils.sanitizeString(line) .. "\n"
                end
            end
        end
    end
    return yaml .. "\n"
end

-- 生成任务组的YAML字符串（按日期分组）
local function generateTasksYamlGroupedByDate(tasks, title, indent)
    local yaml = "- " .. title .. "\n  task:\n"

    -- 按日期分组
    local tasksByDate = {}
    for _, task in ipairs(tasks) do
        local completedDate = task.doneAt:match("^(%d%d%d%d%-%d%d%-%d%d)")
        if not tasksByDate[completedDate] then
            tasksByDate[completedDate] = {}
        end
        table.insert(tasksByDate[completedDate], task)
    end

    -- 按日期顺序输出
    local dates = {}
    for date, _ in pairs(tasksByDate) do
        table.insert(dates, date)
    end
    table.sort(dates)

    for _, date in ipairs(dates) do
        yaml = yaml .. "    - date: " .. date .. "\n      task:\n"
        for _, task in ipairs(tasksByDate[date]) do
            yaml = yaml .. generateTaskYaml(task, "        ")
        end
    end

    return yaml
end

-- 生成简单任务列表的YAML字符串（不分组）
local function generateTasksYamlSimple(tasks, title, indent)
    local yaml = "- " .. title .. "\n  task:\n"
    for _, task in ipairs(tasks) do
        yaml = yaml .. generateTaskYaml(task, "    ")
    end
    return yaml
end

-- 核心导出函数：导出特定日期的任务
function export.exportTasksForDate(tasks, dateStr, dateLabel)
    if not utils.isValidDate(dateStr) then
        notifs.dateFormatError()
        return
    end

    -- 查找在指定日期完成的任务
    local completedTasks = {}
    for _, task in ipairs(tasks) do
        if task.isDone and task.doneAt and not shouldExcludeFromExport(task) then
            local completedDate = task.doneAt:match("^(%d%d%d%d%-%d%d%-%d%d)")
            if completedDate == dateStr then
                table.insert(completedTasks, task)
            end
        end
    end

    if #completedTasks == 0 then
        notifs.exportNoTasks(dateLabel or dateStr)
        return
    end

    -- 排序并生成YAML
    sortTasksByCompletionTime(completedTasks)
    local yaml = generateTasksYamlSimple(completedTasks, "date: " .. dateStr)

    -- 复制到剪贴板
    hs.pasteboard.setContents(yaml)
    notifs.exportCompleted(dateLabel or dateStr, #completedTasks)
end

-- 核心导出函数：导出时间范围内的任务
function export.exportTasksForRange(tasks, startDate, endDate, rangeLabel)
    if not utils.isValidDate(startDate) or not utils.isValidDate(endDate) then
        notifs.dateFormatError()
        return
    end

    -- 查找在时间范围内完成的任务
    local completedTasks = {}
    for _, task in ipairs(tasks) do
        if task.isDone and task.doneAt and not shouldExcludeFromExport(task) then
            local completedDate = task.doneAt:match("^(%d%d%d%d%-%d%d%-%d%d)")
            if completedDate and completedDate >= startDate and completedDate <= endDate then
                table.insert(completedTasks, task)
            end
        end
    end

    if #completedTasks == 0 then
        notifs.exportNoTasks(rangeLabel or (startDate .. " - " .. endDate))
        return
    end

    -- 排序并生成YAML（按日期分组）
    sortTasksByCompletionTime(completedTasks)
    local yaml = generateTasksYamlGroupedByDate(completedTasks, rangeLabel or ("date_range: " .. startDate .. " - " .. endDate))

    -- 复制到剪贴板
    hs.pasteboard.setContents(yaml)
    notifs.exportCompleted(rangeLabel or (startDate .. " - " .. endDate), #completedTasks)
end

-- 导出本周已完成任务（向后兼容）
function export.exportThisWeekTasks(tasks)
    local mondayStr, todayStr, weekNum = utils.getThisWeekRange()
    local rangeLabel = "week: w" .. weekNum .. " (" .. mondayStr .. " - " .. todayStr .. ")"
    export.exportTasksForRange(tasks, mondayStr, todayStr, rangeLabel)
end

-- 导出上周已完成任务
function export.exportLastWeekTasks(tasks)
    local mondayStr, sundayStr, weekNum = utils.getLastWeekRange()
    local rangeLabel = "last_week: w" .. weekNum .. " (" .. mondayStr .. " - " .. sundayStr .. ")"
    export.exportTasksForRange(tasks, mondayStr, sundayStr, rangeLabel)
end

-- 自定义日期导出
function export.exportCustomDateTasks(tasks)
    local button, dateStr = hs.dialog.textPrompt(
            "导出已完成任务",
            "请输入要导出的日期 (格式: YYYY-MM-DD):",
            utils.getCurrentDate(),
            "导出",
            "取消"
    )
    if button ~= "导出" then
        return
    end

    export.exportTasksForDate(tasks, dateStr, nil)
end

return export
