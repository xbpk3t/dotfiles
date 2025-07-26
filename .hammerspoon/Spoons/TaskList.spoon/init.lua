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
            local taskName = currentTask.name

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
    -- 编辑任务的实现可以后续添加
    notifications.sendNotification("功能提示", "编辑任务功能待实现", 3)
end

local function completeTask(index)
    if not taskList[index] or taskList[index].isDone then return end

    local task = taskList[index]
    local button = hs.dialog.blockAlert(
            "完成任务",
            "确定要完成任务 \"" .. task.name .. "\" 吗？",
            "完成",
            "取消"
    )
    if button == "完成" then
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
        notifications.sendNotification("任务完成",
            "任务已完成！评分: " .. scoring.calculateScore(task) .. "/5", 5)
    end
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

-- 创建菜单项
local function createMenu()
    local callbacks = {
        selectTask = selectTask,
        editTask = editTask,
        completeTask = completeTask,
        deleteTask = deleteTask,
        addTask = addTask,
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

    notifications.sendNotification("TaskList", "多任务管理器已启动", 3)

    obj.logger.i("TaskList started")
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
