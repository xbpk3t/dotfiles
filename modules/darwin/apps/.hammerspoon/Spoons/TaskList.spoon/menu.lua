--- === TaskList Menu ===
---
--- 菜单创建和UI组件模块
---

local menu = {}
local utils = dofile(hs.configdir .. "/Spoons/TaskList.spoon/utils.lua")
local tasks = dofile(hs.configdir .. "/Spoons/TaskList.spoon/tasks.lua")
local export = dofile(hs.configdir .. "/Spoons/TaskList.spoon/export.lua")
local notifs = dofile(hs.configdir .. "/Spoons/TaskList.spoon/tasklist_notifs.lua")

-- 创建菜单项
function menu.createMenu(taskList, currentTaskId, maxTasks, callbacks)
    local menuItems = {}
    local activeTasks = tasks.getActiveTasks(taskList)

    -- 当前任务显示
    local currentTask = tasks.findTaskById(taskList, currentTaskId)
    if currentTask and not currentTask.isDone then
        table.insert(menuItems, {
            title = "当前: " .. utils.sanitizeString(currentTask.name),
            disabled = true
        })
        table.insert(menuItems, { title = "-" })
    end

    -- 按日期分组显示活跃任务
    if #activeTasks > 0 then
        table.insert(menuItems, {
            title = "活跃任务 (" .. #activeTasks .. "/" .. maxTasks .. ")",
            disabled = true
        })

        -- 按日期分组任务
        local tasksByDate = {}
        for _, activeTask in ipairs(activeTasks) do
            local task = activeTask.task
            local date = task.date
            if not tasksByDate[date] then
                tasksByDate[date] = {}
            end
            table.insert(tasksByDate[date], activeTask)
        end

        -- 获取所有日期并排序
        local dates = {}
        for date, _ in pairs(tasksByDate) do
            table.insert(dates, date)
        end
        table.sort(dates)

        -- 按日期显示任务
        for _, date in ipairs(dates) do
            local dateTitle = (date == utils.getCurrentDate()) and "📅 今天" or "📅 " .. date
            table.insert(menuItems, { title = dateTitle, disabled = true })

            for _, activeTask in ipairs(tasksByDate[date]) do
                local task = activeTask.task
                local index = activeTask.index
                local prefix = (task.id == currentTaskId) and "● " or "○ "

                -- 清理任务名称并使用 UTF-8 安全的字符串截取
                local maxLength = 50
                local displayTask = utils.sanitizeString(task.name)  -- 清理多行字符串
                local taskNameLength = 0
                local i = 1
                while i <= string.len(displayTask) do
                    local byteCount = utils.SubStringGetByteCount(displayTask, i)
                    if taskNameLength >= maxLength then
                        displayTask = utils.SubString(displayTask, 1, maxLength - 3) .. "..."
                        break
                    end
                    taskNameLength = taskNameLength + 1
                    i = i + byteCount
                end

                -- 简洁的单行样式，移除checkbox
                local prefix = (task.id == currentTaskId) and "● " or "○ "
                local taskTitle = "  " .. prefix .. displayTask

                table.insert(menuItems, {
                    title = taskTitle,
                    fn = function() if callbacks.selectTask then callbacks.selectTask(index) end end,  -- 默认点击选择任务
                    menu = {
                        { title = "完成任务", fn = function() if callbacks.completeTask then callbacks.completeTask(index) end end },
                        { title = "编辑任务", fn = function() if callbacks.editTask then callbacks.editTask(index) end end },
                        { title = "删除任务", fn = function() if callbacks.deleteTask then callbacks.deleteTask(index) end end }
                    }
                })
            end
        end
        table.insert(menuItems, { title = "-" })
    end

    -- 操作选项
    table.insert(menuItems, { title = "➕ 添加新任务", fn = function() if callbacks.addTask then callbacks.addTask() end end })

    table.insert(menuItems, {
        title = "📤 导出已完成任务",
        menu = {
            { title = "今天 (" .. utils.getCurrentDate() .. ")", fn = function() export.exportTasksForDate(taskList, utils.getCurrentDate(), "今天") end },
            { title = "昨天 (" .. utils.getYesterdayDate() .. ")", fn = function() export.exportTasksForDate(taskList, utils.getYesterdayDate(), "昨天") end },
            { title = "本周", fn = function()
                local _, _, weekNum, year = utils.getRelativeWeekRange(0)
                export.exportWeekTasks(taskList, year, weekNum)
            end },
            { title = "上周", fn = function()
                local _, _, weekNum, year = utils.getRelativeWeekRange(-1)
                export.exportWeekTasks(taskList, year, weekNum)
            end },
            { title = "自定义", fn = function() export.exportCustomDateTasks(taskList) end },
        }
    })

    table.insert(menuItems, { title = "-" })

    -- 显示已完成任务数量
    local completedCount = 0
    for _, task in ipairs(taskList) do
        if task.isDone then completedCount = completedCount + 1 end
    end

    if completedCount > 0 then
        table.insert(menuItems, { title = "已完成任务: " .. completedCount, disabled = true })
        table.insert(menuItems, { title = "-" })
    end

    table.insert(menuItems, { title = "退出", fn = function() if callbacks.exit then callbacks.exit() end end })
    return menuItems
end

return menu
