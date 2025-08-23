--- === TaskList ===
---
--- 多任务 Hammerspoon menubar 管理器
--- 提供任务管理、倒计时、数据持久化等功能
---
--- Download: [https://github.com/your-repo/TaskList.spoon](https://github.com/your-repo/TaskList.spoon)

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "TaskList"
obj.version = "1.0.0"
obj.author = "yyzw@live.com"
obj.homepage = "http://lucc.dev/"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new('TaskList')

-- 加载模块
local spoonPath = hs.configdir .. "/Spoons/TaskList.spoon"
local utils = dofile(spoonPath .. "/utils.lua")
local data = dofile(spoonPath .. "/data.lua")
local scoring = dofile(spoonPath .. "/scoring.lua")
local notifications = dofile(spoonPath .. "/notifications.lua")
local tasks = dofile(spoonPath .. "/tasks.lua")
local countdown = dofile(spoonPath .. "/countdown.lua")
local export = dofile(spoonPath .. "/export.lua")
local menu = dofile(spoonPath .. "/menu.lua")
local cronTask = dofile(spoonPath .. "/cron_task.lua")

-- 全局状态变量
local menubar = nil  -- 初始化为 nil，在 start() 中创建
local taskList = {}  -- 存储所有任务
local currentTaskId = nil  -- 当前选中的任务ID
local maxTasks = 20  -- 最大任务数量

-- 更新菜单栏显示
local function updateMenubar()
    if menubar then
        local displayText = "无任务"

        local currentTask = tasks.findTaskById(taskList, currentTaskId)
        if currentTask and not currentTask.isDone then
            -- 清理任务名称，处理多行字符串
            local taskName = utils.sanitizeString(currentTask.name)

            -- 使用 UTF-8 安全的字符串截取
            local maxLength = 20
            local taskNameLength = 0
            local i = 1
            while i <= string.len(taskName) do
                local byteCount = utils.SubStringGetByteCount(taskName, i)
                if taskNameLength >= maxLength then
                    taskName = utils.SubString(taskName, 1, maxLength - 3) .. "..."
                    break
                end
                taskNameLength = taskNameLength + 1
                i = i + byteCount
            end

            -- 如果有倒计时，显示倒计时
            local countdownState = countdown.getCountdownState()
            if countdownState.remainingSeconds > 0 then
                local minutes = math.floor(countdownState.remainingSeconds / 60)
                local seconds = countdownState.remainingSeconds % 60
                local timeStr = string.format("%d:%02d", minutes, seconds)
                local pauseIcon = countdownState.isPaused and "⏸" or "⏱"
                displayText = pauseIcon .. " " .. timeStr .. " | " .. taskName
            else
                displayText = taskName
            end
        end

        -- 使用更小的字体
        local styledText = hs.styledtext.new(displayText, {
            font = { name = "Helvetica", size = 12 }
        })
        menubar:setTitle(styledText)
    end
end

-- 加载任务数据
local function loadTasks()
    taskList, currentTaskId = data.loadTasks()

    -- 加载和集成cron任务
    local cronTaskFilePath = spoonPath .. "/CronTask.yml"
    taskList = cronTask.loadAndIntegrateCronTasks(taskList, cronTaskFilePath)
end

-- 保存任务数据
local function saveTasks()
    data.saveTasks(taskList, currentTaskId)
end

-- 添加新任务（分步对话框）
local function addTask()
    local activeTasks = tasks.getActiveTasks(taskList)
    if #activeTasks >= maxTasks then
        notifications.sendNotification("任务管理器", "活跃任务数量已达上限 (" .. maxTasks .. ")", 5)
        return
    end

    -- 第一步：获取任务名称
    local button, taskName = hs.dialog.textPrompt(
            "添加新任务 - 步骤 1/3",
            "请输入任务名称:",
            "",
            "下一步",
            "取消"
    )
    if button ~= "下一步" or not taskName or taskName == "" then
        return
    end

    -- 第二步：获取日期
    local button2, dateStr = hs.dialog.textPrompt(
            "添加新任务 - 步骤 2/3",
            "请输入日期 (格式: YYYY-MM-DD):",
            utils.getCurrentDate(),
            "下一步",
            "取消"
    )
    if button2 ~= "下一步" then
        return
    end

    if not utils.isValidDate(dateStr) then
        notifications.sendNotification("输入错误", "日期格式错误，请使用 YYYY-MM-DD 格式", 5)
        return
    end

    -- 第三步：获取预计耗时
    local button3, estimatedStr = hs.dialog.textPrompt(
            "添加新任务 - 步骤 3/3",
            "请输入预计耗时 (几个E1f，每个E1f=40分钟):",
            "1",
            "完成",
            "取消"
    )
    if button3 ~= "完成" then
        return
    end

    local estimatedTime = tonumber(estimatedStr) or 1
    if estimatedTime < 1 then
        estimatedTime = 1
    end

    -- 创建新任务
    local newTask = tasks.createTask(taskName, dateStr, estimatedTime)
    table.insert(taskList, newTask)
    tasks.sortTasks(taskList)

    updateMenubar()
    saveTasks()

    notifications.sendNotification("任务管理器", "任务已添加: " .. taskName, 3)
end

-- 任务管理函数
local function selectTask(index)
    if not taskList[index] or taskList[index].isDone then return end

    -- 如果有正在进行的任务，停止任务
    local currentTask = tasks.findTaskById(taskList, currentTaskId)
    if currentTask and not currentTask.isDone then
        tasks.stopTask(currentTask)
        countdown.stopCountdown(currentTaskId)
    end

    currentTaskId = taskList[index].id

    -- 如果任务还没有开始时间，则启动任务
    if not taskList[index].startTime then
        tasks.startTask(taskList[index])
    end

    -- 检查是否有保存的倒计时时间
    local minutes, seconds = countdown.resumeTaskCountdown(taskList[index].id, updateMenubar)
    if minutes and seconds then
        notifications.sendNotification("恢复任务",
            string.format("已恢复: %s (剩余: %d:%02d)", taskList[index].name, minutes, seconds), 3)
    else
        -- 计算新的倒计时时间
        local countdownMinutes = countdown.calculateCountdownTime(taskList[index])
        countdown.startCountdown(countdownMinutes, currentTaskId, updateMenubar)
        notifications.sendNotification("当前任务",
            "已设置: " .. taskList[index].name .. " (倒计时: " .. countdownMinutes .. "分钟)", 3)
    end
    updateMenubar()
    saveTasks()
end

local function editTask(index)
    if not taskList[index] or taskList[index].isDone then return end

    local task = taskList[index]

    -- 第一步：编辑任务名称
    local button1, newName = hs.dialog.textPrompt(
            "编辑任务 - 步骤 1/3",
            "请输入新的任务名称:",
            task.name,
            "下一步",
            "取消"
    )
    if button1 ~= "下一步" then
        return
    end

    if newName == "" then
        notifications.sendNotification("输入错误", "任务名称不能为空", 3)
        return
    end

    -- 第二步：编辑日期
    local button2, newDate = hs.dialog.textPrompt(
            "编辑任务 - 步骤 2/3",
            "请输入新的日期 (格式: YYYY-MM-DD):",
            task.date,
            "下一步",
            "取消"
    )
    if button2 ~= "下一步" then
        return
    end

    if not utils.isValidDate(newDate) then
        notifications.sendNotification("输入错误", "日期格式错误", 3)
        return
    end

    -- 第三步：编辑预计耗时
    local button3, newEstimatedStr = hs.dialog.textPrompt(
            "编辑任务 - 步骤 3/3",
            "请输入新的预计耗时 (几个E1f，每个E1f=40分钟):",
            tostring(task.estimatedTime),
            "完成",
            "取消"
    )
    if button3 ~= "完成" then
        return
    end

    local newEstimatedTime = tonumber(newEstimatedStr) or task.estimatedTime
    if newEstimatedTime < 1 then
        newEstimatedTime = 1
    end

    -- 更新任务信息
    local oldName = task.name
    task.name = newName
    task.date = newDate
    task.estimatedTime = newEstimatedTime

    -- 重新生成任务ID（因为内容改变了）
    task.id = utils.generateTaskId(task.addTime, newName, newDate, newEstimatedTime)

    -- 如果这是当前任务，更新当前任务ID
    if currentTaskId == task.id then
        currentTaskId = task.id
    end

    -- 重新排序任务
    tasks.sortTasks(taskList)

    updateMenubar()
    saveTasks()

    notifications.sendNotification("任务管理器",
        string.format("任务已更新: %s -> %s", oldName, newName), 3)
end

local function completeTask(index)
    if not taskList[index] or taskList[index].isDone then return end

    local task = taskList[index]

    -- 直接完成任务，不需要弹窗确认
    tasks.stopTask(task)
    tasks.completeTask(task)

    -- 如果这是当前任务，清除当前任务ID
    if task.id == currentTaskId then
        countdown.stopCountdown(currentTaskId)
        currentTaskId = nil
        -- 尝试选择下一个活跃任务
        local activeTasks = tasks.getActiveTasks(taskList)
        if #activeTasks > 0 then
            for i, activeTask in ipairs(activeTasks) do
                if activeTask.index ~= index then
                    currentTaskId = activeTask.task.id
                    break
                end
            end
        end
    end

    updateMenubar()
    saveTasks()
    -- 移除弹窗通知，保持菜单打开状态
end

local function deleteTask(index)
    if not taskList[index] then return end

    local task = taskList[index]
    local button = hs.dialog.blockAlert(
            "删除任务",
            "确定要删除任务 \"" .. task.name .. "\" 吗？\n注意：此操作不可恢复！",
            "删除",
            "取消"
    )
    if button == "删除" then
        -- 如果删除的是当前任务，停止任务
        if task.id == currentTaskId then
            tasks.stopTask(task)
            countdown.stopCountdown(currentTaskId)
            currentTaskId = nil
        end

        table.remove(taskList, index)

        -- 尝试选择下一个活跃任务
        if not currentTaskId then
            local activeTasks = tasks.getActiveTasks(taskList)
            if #activeTasks > 0 then
                currentTaskId = activeTasks[1].task.id
            end
        end

        updateMenubar()
        saveTasks()
        notifications.sendNotification("任务管理器", "任务已删除", 3)
    end
end

-- 手动重新加载 CronTask 的函数
local function reloadCronTasks()
    local cronTaskFilePath = spoonPath .. "/CronTask.yml"
    local oldTaskCount = #taskList
    taskList = cronTask.loadAndIntegrateCronTasks(taskList, cronTaskFilePath)
    local newTaskCount = #taskList

    if newTaskCount > oldTaskCount then
        tasks.sortTasks(taskList)
        updateMenubar()
        saveTasks()
        notifications.sendNotification("CronTask",
            string.format("已重新加载，新增 %d 个周期任务", newTaskCount - oldTaskCount), 3)
    else
        notifications.sendNotification("CronTask", "重新加载完成，没有新任务", 3)
    end
end

-- 创建菜单项
local function createMenu()
    local callbacks = {
        selectTask = selectTask,
        editTask = editTask,
        completeTask = completeTask,
        deleteTask = deleteTask,
        addTask = addTask,
        reloadCronTasks = reloadCronTasks,
        getCountdownState = function() return countdown.getCountdownState() end,
        toggleCountdown = function() return countdown.toggleCountdown() end,
        exit = function()
            menubar:delete()
            menubar = nil
        end
    }

    return menu.createMenu(taskList, currentTaskId, maxTasks, callbacks)
end

--- TaskList:start()
--- Method
--- 启动 TaskList
---
--- Parameters:
---  * None
---
--- Returns:
---  * The TaskList object
function obj:start()
    -- 创建 menubar
    menubar = hs.menubar.new()

    -- 设置菜单
    menubar:setMenu(createMenu)

    -- 点击菜单栏图标时快速添加任务
    menubar:setClickCallback(function()
        addTask()
    end)

    -- 初始化
    loadTasks()
    tasks.sortTasks(taskList)
    updateMenubar()

    -- 如果有活跃任务但没有当前任务，选择第一个活跃任务
    if not currentTaskId then
        local activeTasks = tasks.getActiveTasks(taskList)
        if #activeTasks > 0 then
            currentTaskId = activeTasks[1].task.id
        end
    end

    -- 如果有当前任务，启动任务
    local currentTask = tasks.findTaskById(taskList, currentTaskId)
    if currentTask and not currentTask.isDone then
        -- 如果任务还没有开始时间，则启动任务
        if not currentTask.startTime then
            tasks.startTask(currentTask)
        end

        -- 启动对应的倒计时
        local countdownMinutes = countdown.calculateCountdownTime(currentTask)
        countdown.startCountdown(countdownMinutes, currentTaskId, updateMenubar)
    end

    -- 设置定时器，每分钟更新一次任务实际时间
    obj.updateTimer = hs.timer.new(60, function()
        local currentTask = tasks.findTaskById(taskList, currentTaskId)
        if currentTask then
            tasks.updateTaskActualTime(currentTask)
            saveTasks()
        end
    end)
    obj.updateTimer:start()

    -- 检查并加载新 CronTask 的函数
    local function checkAndLoadCronTasks()
        local cronTaskFilePath = spoonPath .. "/CronTask.yml"
        local oldTaskCount = #taskList
        taskList = cronTask.loadAndIntegrateCronTasks(taskList, cronTaskFilePath)
        local newTaskCount = #taskList

        if newTaskCount > oldTaskCount then
            tasks.sortTasks(taskList)
            updateMenubar()
            saveTasks()
            notifications.sendNotification("CronTask",
                string.format("已加载 %d 个新的周期任务", newTaskCount - oldTaskCount), 3)
        end
    end

    -- 设置定时器，每小时检查并加载新的 CronTask
    obj.cronCheckTimer = hs.timer.new(3600, checkAndLoadCronTasks) -- 每小时检查一次
    obj.cronCheckTimer:start()

    -- 绑定快捷键
    obj:setupHotkeys()

    notifications.sendNotification("TaskList", "多任务管理器已启动", 3)

    obj.logger.i("TaskList started")
    return self
end

--- TaskList:setupHotkeys()
--- Method
--- 设置快捷键
---
--- Parameters:
---  * None
---
--- Returns:
---  * The TaskList object
function obj:setupHotkeys()
    -- 绑定 Option+Control+P 来暂停/恢复倒计时
    obj.pauseHotkey = hs.hotkey.bind({"alt", "ctrl"}, "p", function()
        obj.logger.i("Pause hotkey triggered")
        print("TaskList: Pause hotkey triggered")  -- 添加控制台日志

        local success = countdown.toggleCountdown()
        if success then
            local countdownState = countdown.getCountdownState()
            local status = countdownState.isPaused and "已暂停" or "已恢复"
            notifications.sendNotification("倒计时控制", "倒计时" .. status, 2)
            obj.logger.i("Countdown toggled: " .. status)
            print("TaskList: Countdown toggled: " .. status)
        else
            notifications.sendNotification("倒计时控制", "当前没有运行中的倒计时", 2)
            obj.logger.i("No active countdown to toggle")
            print("TaskList: No active countdown to toggle")
        end
    end)

    -- 绑定 Option+Control+D 来完成当前任务
    obj.completeHotkey = hs.hotkey.bind({"alt", "ctrl"}, "d", function()
        obj.logger.i("Complete task hotkey triggered")
        print("TaskList: Complete task hotkey triggered")  -- 添加控制台日志

        if currentTaskId then
            local currentTask, index = tasks.findTaskById(taskList, currentTaskId)
            if currentTask and not currentTask.isDone then
                completeTask(index)
                notifications.sendNotification("任务完成", "当前任务已完成: " .. utils.sanitizeString(currentTask.name), 3)
                obj.logger.i("Current task completed: " .. currentTask.name)
                print("TaskList: Current task completed: " .. currentTask.name)
            else
                notifications.sendNotification("任务完成", "当前任务已完成或不存在", 2)
                obj.logger.i("Current task already completed or not found")
                print("TaskList: Current task already completed or not found")
            end
        else
            notifications.sendNotification("任务完成", "没有当前任务", 2)
            obj.logger.i("No current task to complete")
            print("TaskList: No current task to complete")
        end
    end)

    obj.logger.i("Hotkeys setup completed")
    print("TaskList: Hotkeys setup completed")
    return self
end

--- TaskList:stop()
--- Method
--- 停止 TaskList
---
--- Parameters:
---  * None
---
--- Returns:
---  * The TaskList object
function obj:stop()
    if menubar then
        menubar:delete()
        menubar = nil
    end

    local countdownState = countdown.getCountdownState()
    if countdownState.timer then
        countdown.stopCountdown(currentTaskId)
    end

    if obj.updateTimer then
        obj.updateTimer:stop()
        obj.updateTimer = nil
    end

    if obj.cronCheckTimer then
        obj.cronCheckTimer:stop()
        obj.cronCheckTimer = nil
    end

    -- 清理快捷键
    if obj.pauseHotkey then
        obj.pauseHotkey:delete()
        obj.pauseHotkey = nil
    end

    if obj.completeHotkey then
        obj.completeHotkey:delete()
        obj.completeHotkey = nil
    end

    -- 保存数据
    saveTasks()

    obj.logger.i("TaskList stopped")
    return self
end

--- TaskList:bindHotkeys(mapping)
--- Method
--- 绑定热键
---
--- Parameters:
---  * mapping - 热键映射表
---
--- Returns:
---  * The TaskList object
function obj:bindHotkeys(mapping)
    local def = {
        toggle_pause = function() countdown.toggleCountdown() end,
        add_task = function() addTask() end,
        show_tasks = function()
            if menubar then
                menubar:popupMenu(hs.mouse.absolutePosition())
            end
        end
    }
    hs.spoons.bindHotkeysToSpec(def, mapping)

    return self
end

return obj
