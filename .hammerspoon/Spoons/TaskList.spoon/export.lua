--- === TaskList Export ===
---
--- 任务导出功能模块
---

local export = {}
local utils = dofile(hs.configdir .. "/Spoons/TaskList.spoon/utils.lua")
local scoring = dofile(hs.configdir .. "/Spoons/TaskList.spoon/scoring.lua")
local notifications = dofile(hs.configdir .. "/Spoons/TaskList.spoon/notifications.lua")

-- 配置不导出的 CronTask 类型
local EXCLUDED_CRON_TYPES = {
    "daily",
    "2daily",
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

-- 通用导出函数
function export.exportTasksForDate(tasks, dateStr, dateLabel)
    if not utils.isValidDate(dateStr) then
        notifications.sendNotification("输入错误", "日期格式错误", 3)
        return
    end

    -- 查找在指定日期完成的任务（按完成时间而不是任务日期）
    local completedTasks = {}
    for _, task in ipairs(tasks) do
        if task.isDone and task.doneAt and not shouldExcludeFromExport(task) then
            -- 提取完成日期（doneAt 格式：YYYY-MM-DD HH:MM）
            local completedDate = task.doneAt:match("^(%d%d%d%d%-%d%d%-%d%d)")
            if completedDate == dateStr then
                table.insert(completedTasks, task)
            end
        end
    end

    if #completedTasks == 0 then
        notifications.sendNotification("导出结果", (dateLabel or dateStr) .. " 没有已完成的任务", 3)
        return
    end

    -- 按完成时间排序 (doneAt 升序)
    table.sort(completedTasks, function(a, b)
        local timeA = a.doneAt or "0000-00-00 00:00"
        local timeB = b.doneAt or "0000-00-00 00:00"
        return timeA < timeB
    end)

    -- 生成YAML格式
    local yaml = "- date: " .. dateStr .. "\n  task:\n"
    for _, task in ipairs(completedTasks) do
        yaml = yaml .. "    - name: " .. task.name .. "\n"
        if task.doneAt then
            yaml = yaml .. "      doneAt: " .. task.doneAt .. "\n"
        end
        if task.estimatedTime and task.estimatedTime > 0 then
            yaml = yaml .. "      PD: " .. (task.estimatedTime * 40) .. "min\n"
        end
        if task.actualTime and task.actualTime > 0 then
            yaml = yaml .. "      AD: " .. task.actualTime .. "min\n"
        end
        local score = scoring.calculateScore(task)
        if score > 0 then
            yaml = yaml .. "      score: " .. score .. "\n"
        end
        yaml = yaml .. "\n"
    end

    -- 复制到剪贴板
    hs.pasteboard.setContents(yaml)
    notifications.sendNotification("导出完成", "已导出 " .. (dateLabel or dateStr) .. " 的 " .. #completedTasks .. " 个任务到剪贴板", 5)
end

-- 导出本周已完成任务
function export.exportThisWeekTasks(tasks)
    local mondayStr, todayStr, weekNum = utils.getThisWeekRange()

    -- 查找本周完成的任务
    local completedTasks = {}
    for _, task in ipairs(tasks) do
        if task.isDone and task.doneAt and not shouldExcludeFromExport(task) then
            local completedDate = task.doneAt:match("^(%d%d%d%d%-%d%d%-%d%d)")
            if completedDate and completedDate >= mondayStr and completedDate <= todayStr then
                table.insert(completedTasks, task)
            end
        end
    end

    if #completedTasks == 0 then
        notifications.sendNotification("导出结果", "本周没有已完成的任务", 3)
        return
    end

    -- 按完成时间排序
    table.sort(completedTasks, function(a, b)
        local timeA = a.doneAt or "0000-00-00 00:00"
        local timeB = b.doneAt or "0000-00-00 00:00"
        return timeA < timeB
    end)

    -- 按日期分组
    local tasksByDate = {}
    for _, task in ipairs(completedTasks) do
        local completedDate = task.doneAt:match("^(%d%d%d%d%-%d%d%-%d%d)")
        if not tasksByDate[completedDate] then
            tasksByDate[completedDate] = {}
        end
        table.insert(tasksByDate[completedDate], task)
    end

    -- 生成YAML格式
    local yaml = "- week: w" .. weekNum .. " (" .. mondayStr .. " - " .. todayStr .. ")\n  task:\n"

    -- 按日期顺序输出
    local dates = {}
    for date, _ in pairs(tasksByDate) do
        table.insert(dates, date)
    end
    table.sort(dates)

    for _, date in ipairs(dates) do
        yaml = yaml .. "    - date: " .. date .. "\n      task:\n"
        for _, task in ipairs(tasksByDate[date]) do
            yaml = yaml .. "        - name: " .. task.name .. "\n"
            if task.doneAt then
                yaml = yaml .. "          doneAt: " .. task.doneAt .. "\n"
            end
            if task.estimatedTime and task.estimatedTime > 0 then
                yaml = yaml .. "          PD: " .. (task.estimatedTime * 40) .. "min\n"
            end
            if task.actualTime and task.actualTime > 0 then
                yaml = yaml .. "          AD: " .. task.actualTime .. "min\n"
            end
            local score = scoring.calculateScore(task)
            if score > 0 then
                yaml = yaml .. "          score: " .. score .. "\n"
            end
            yaml = yaml .. "\n"
        end
    end

    -- 复制到剪贴板
    hs.pasteboard.setContents(yaml)
    notifications.sendNotification("导出完成", "已导出本周的 " .. #completedTasks .. " 个任务到剪贴板", 5)
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
    if button ~= "导出" then return end

    export.exportTasksForDate(tasks, dateStr, nil)
end

return export
