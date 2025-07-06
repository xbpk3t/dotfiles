-- 多任务 Hammerspoon menubar 管理器
local menubar = hs.menubar.new()
local tasks = {}  -- 存储所有任务
local currentTaskId = nil  -- 当前选中的任务ID
local maxTasks = 20  -- 最大任务数量

local countdownTimer = nil  -- 倒计时计时器
local remainingSeconds = 0  -- 剩余秒数
local isPaused = false      -- 是否暂停
local taskCountdowns = {}   -- 存储每个任务的剩余倒计时时间（按任务ID存储）

-- 简单的字符串hash函数
local function simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) % 2147483647
    end
    return hash
end

-- 生成任务ID的函数（hash(添加时间戳 + 任务内容)）
local function generateTaskId(addTime, taskName, date, estimatedTime)
    local content = tostring(addTime) .. "|" .. taskName .. "|" .. date .. "|" .. tostring(estimatedTime)
    return tostring(simpleHash(content))
end

-- 根据任务ID查找任务
local function findTaskById(taskId)
    if not taskId then return nil end
    for i, task in ipairs(tasks) do
        if task.id == taskId then
            return task, i
        end
    end
    return nil, nil
end

-- 数据持久化文件路径
local dataFile = hs.configdir .. "/tasks_data.json"

-- UTF-8 字符串处理函数
--返回截取的实际Index
function SubStringGetTrueIndex(str, index)
    local curIndex = 0
    local i = 1
    local lastCount = 1
    repeat
        lastCount = SubStringGetByteCount(str, i)
        i = i + lastCount
        curIndex = curIndex + 1
    until (curIndex >= index)
    return i - lastCount
end

--返回当前字符实际占用的字符数
function SubStringGetByteCount(str, index)
    local curByte = string.byte(str, index)
    local byteCount = 1
    if curByte == nil then
        byteCount = 0
    elseif curByte > 0 and curByte <= 127 then
        byteCount = 1
    elseif curByte >= 192 and curByte <= 223 then
        byteCount = 2
    elseif curByte >= 224 and curByte <= 239 then
        byteCount = 3
    elseif curByte >= 240 and curByte <= 247 then
        byteCount = 4
    end
    return byteCount
end

--截取中英混合的字符串
function SubString(str, startIndex, endIndex)
    if type(str) ~= "string" then
        return
    end
    if startIndex == nil or startIndex < 0 then
        return
    end

    if endIndex == nil or endIndex < 0 then
        return
    end

    return string.sub(str, SubStringGetTrueIndex(str, startIndex),
            SubStringGetTrueIndex(str, endIndex + 1) - 1)
end

-- 获取当前日期字符串
local function getCurrentDate()
    return os.date("%Y-%m-%d")
end

-- 获取昨天日期
local function getYesterdayDate()
    return os.date("%Y-%m-%d", os.time() - 24 * 60 * 60)
end

-- 获取本周的日期范围（周一到今天）
local function getThisWeekRange()
    local today = os.time()
    local todayWeekday = tonumber(os.date("%w", today)) -- 0=Sunday, 1=Monday, ...

    -- 计算本周一的日期
    local mondayOffset = (todayWeekday == 0) and 6 or (todayWeekday - 1)
    local monday = today - mondayOffset * 24 * 60 * 60

    local mondayStr = os.date("%Y-%m-%d", monday)
    local todayStr = os.date("%Y-%m-%d", today)

    -- 计算周数
    local weekNum = tonumber(os.date("%W", today))

    return mondayStr, todayStr, weekNum
end

-- 获取当前时间字符串
local function getCurrentTime()
    return os.date("%H:%M")
end

-- 验证日期格式
local function isValidDate(dateStr)
    if not dateStr then return false end
    local year, month, day = dateStr:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if not year then return false end
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    if not year or not month or not day then return false end
    if month < 1 or month > 12 then return false end
    if day < 1 or day > 31 then return false end
    return true
end

-- 计算评分 (1-5分)
local function calculateScore(task)
    if not task.isDone or task.estimatedTime == 0 then
        return 0
    end

    local timeRatio = task.actualTime / (task.estimatedTime * 40) -- 40分钟为一个单位
    local baseScore = 3 -- 基础分数

    -- 根据时间比例调整分数
    if timeRatio <= 0.8 then
        baseScore = baseScore + 1.5  -- 提前完成
    elseif timeRatio <= 1.0 then
        baseScore = baseScore + 0.5  -- 按时完成
    elseif timeRatio <= 1.2 then
        baseScore = baseScore - 0.5  -- 轻微超时
    else
        baseScore = baseScore - 1.5  -- 严重超时
    end

    -- 确保分数在1-5范围内
    return math.max(1, math.min(5, math.floor(baseScore + 0.5)))
end

-- 前置声明函数，解决函数调用顺序问题
local updateMenubar
local startCountdown
local stopCountdown
local toggleCountdown
local calculateCountdownTime

-- 安全的通知发送函数
local function sendNotification(title, text, withdrawAfter, soundName)
    withdrawAfter = withdrawAfter or 3

    local notification = hs.notify.new({
        title = title or "任务管理器",
        informativeText = text or "",
        withdrawAfter = withdrawAfter
    })

    if soundName then
        notification:soundName(soundName)
    end

    local success = pcall(function()
        notification:send()
    end)

    if not success then
        print("通知发送失败: " .. title .. " - " .. text)
        -- 如果通知失败，至少在控制台输出
        print("📢 " .. title .. ": " .. text)
    end

    return success
end

-- 加载任务数据
local function loadTasks()
    local file = io.open(dataFile, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local success, data = pcall(hs.json.decode, content)
        if success and data then
            tasks = data.tasks or {}
            -- 兼容旧数据：如果保存的是索引，转换为ID
            if data.currentTaskIndex and type(data.currentTaskIndex) == "number" and tasks[data.currentTaskIndex] then
                currentTaskId = tasks[data.currentTaskIndex].id
            else
                currentTaskId = data.currentTaskId
            end
            -- 兼容旧数据，为没有新字段的任务添加默认值
            for i, task in ipairs(tasks) do
                if type(task) == "string" then
                    local defaultDate = getCurrentDate()
                    local addTime = math.floor(hs.timer.secondsSinceEpoch() * 1000) -- 为旧任务生成添加时间
                    tasks[i] = {
                        id = generateTaskId(addTime, task, defaultDate, 1),
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
                    task.id = task.id or generateTaskId(task.addTime, task.name or "unknown", task.date or getCurrentDate(), task.estimatedTime or 1)
                    task.date = task.date or getCurrentDate()
                    task.estimatedTime = task.estimatedTime or 1
                    task.actualTime = task.actualTime or 0
                    task.isDone = task.isDone or false
                    task.doneAt = task.doneAt or task.deletedAt or nil
                    task.startTime = task.startTime or nil
                end
            end
        end
    end
end

-- 保存任务数据
local function saveTasks()
    local data = {
        tasks = tasks,
        currentTaskId = currentTaskId
    }
    local file = io.open(dataFile, "w")
    if file then
        file:write(hs.json.encode(data))
        file:close()
    end
end

-- 任务排序函数 (按日期)
local function sortTasks()
    table.sort(tasks, function(a, b)
        if a.isDone ~= b.isDone then
            return not a.isDone  -- 未完成的任务排在前面
        end
        return a.date < b.date
    end)
end

-- 获取活跃任务（未完成的任务）
local function getActiveTasks()
    local activeTasks = {}
    for i, task in ipairs(tasks) do
        if not task.isDone then
            table.insert(activeTasks, {task = task, index = i})
        end
    end
    return activeTasks
end

-- 更新菜单栏显示
updateMenubar = function()
    if menubar then
        local displayText = "无任务"

        local currentTask = findTaskById(currentTaskId)
        if currentTask and not currentTask.isDone then
            local taskName = currentTask.name

            -- 使用 UTF-8 安全的字符串截取
            local maxLength = 20
            local taskNameLength = 0
            local i = 1
            while i <= string.len(taskName) do
                local byteCount = SubStringGetByteCount(taskName, i)
                if taskNameLength >= maxLength then
                    taskName = SubString(taskName, 1, maxLength - 3) .. "..."
                    break
                end
                taskNameLength = taskNameLength + 1
                i = i + byteCount
            end

            -- 如果有倒计时，显示倒计时
            if remainingSeconds > 0 then
                local minutes = math.floor(remainingSeconds / 60)
                local seconds = remainingSeconds % 60
                local timeStr = string.format("%d:%02d", minutes, seconds)
                local pauseIcon = isPaused and "⏸" or "⏱"
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

-- 启动倒计时
startCountdown = function(minutes)
    if countdownTimer and countdownTimer:running() then
        hs.notify.new({
            title = "倒计时提醒",
            informativeText = "倒计时已在运行中",
            withdrawAfter = 3
        }):send()
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

            updateMenubar()

            if remainingSeconds <= 0 then
                -- 倒计时结束，自动续期40分钟
                remainingSeconds = 40 * 60
                if currentTaskId then
                    taskCountdowns[currentTaskId] = remainingSeconds
                end

                hs.notify.new({
                    title = "⏰ 倒计时结束",
                    informativeText = "任务时间到！自动续期40分钟",
                    withdrawAfter = 10,
                    soundName = "Glass"
                }):send()

                updateMenubar()
            end
        end
    end)

    hs.notify.new({
        title = "倒计时启动",
        informativeText = "已启动 " .. minutes .. " 分钟倒计时",
        withdrawAfter = 3
    }):send()
end

-- 停止倒计时
stopCountdown = function()
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
    updateMenubar()
end

-- 暂停/恢复倒计时
toggleCountdown = function()
    if countdownTimer and countdownTimer:running() then
        isPaused = not isPaused
        local status = isPaused and "暂停" or "恢复"
        hs.notify.new({
            title = "倒计时" .. status,
            informativeText = "倒计时已" .. status,
            withdrawAfter = 2
        }):send()
        updateMenubar()
    end
end

-- 启动任务
local function startTask()
    local currentTask = findTaskById(currentTaskId)
    if currentTask and not currentTask.startTime then
        currentTask.startTime = os.time()
        saveTasks()

        -- 启动倒计时
        local totalMinutes = currentTask.estimatedTime * 40
        startCountdown(totalMinutes)

        hs.notify.new({
            title = "任务开始",
            informativeText = "任务 \"" .. currentTask.name .. "\" 已开始",
            withdrawAfter = 3
        }):send()
    end
end

-- 停止任务并记录实际时间
local function stopTask()
    local currentTask = findTaskById(currentTaskId)
    if currentTask and currentTask.startTime then
        local elapsed = os.time() - currentTask.startTime
        currentTask.actualTime = math.floor(elapsed / 60) -- 转换为分钟
        saveTasks()
    end

    -- 停止倒计时
    stopCountdown()
end

-- 添加新任务（分步对话框）
local function addTask()
    local activeTasks = getActiveTasks()
    if #activeTasks >= maxTasks then
        hs.notify.new({
            title = "任务管理器",
            informativeText = "活跃任务数量已达上限 (" .. maxTasks .. ")",
            withdrawAfter = 5
        }):send()
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
        getCurrentDate(),
        "下一步",
        "取消"
    )
    if button2 ~= "下一步" then
        return
    end

    if not isValidDate(dateStr) then
        hs.notify.new({
            title = "输入错误",
            informativeText = "日期格式错误，请使用 YYYY-MM-DD 格式",
            withdrawAfter = 5
        }):send()
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
    local addTime = math.floor(hs.timer.secondsSinceEpoch() * 1000) -- 任务添加时间（精确到毫秒）
    local newTask = {
        id = generateTaskId(addTime, taskName, dateStr, estimatedTime),
        name = taskName,
        date = dateStr,
        addTime = addTime,
        estimatedTime = estimatedTime,
        actualTime = 0,
        isDone = false,
        doneAt = nil,
        startTime = nil
    }

    table.insert(tasks, newTask)
    sortTasks()

    updateMenubar()
    saveTasks()

    hs.notify.new({
        title = "任务管理器",
        informativeText = "任务已添加: " .. taskName,
        withdrawAfter = 3
    }):send()
end

-- 编辑任务（分步对话框）
local function editTask(index)
    if not tasks[index] or tasks[index].isDone then return end

    local task = tasks[index]

    -- 第一步：编辑任务名称
    local button, newName = hs.dialog.textPrompt(
        "编辑任务 - 步骤 1/3",
        "修改任务名称:",
        task.name,
        "下一步",
        "取消"
    )
    if button ~= "下一步" then return end

    if not newName or newName == "" then
        hs.notify.new({
            title = "输入错误",
            informativeText = "任务名称不能为空",
            withdrawAfter = 3
        }):send()
        return
    end

    -- 第二步：编辑日期
    local button2, newDate = hs.dialog.textPrompt(
        "编辑任务 - 步骤 2/3",
        "修改日期 (格式: YYYY-MM-DD):",
        task.date,
        "下一步",
        "取消"
    )
    if button2 ~= "下一步" then return end

    if not isValidDate(newDate) then
        hs.notify.new({
            title = "输入错误",
            informativeText = "日期格式错误",
            withdrawAfter = 3
        }):send()
        return
    end

    -- 第三步：编辑预计耗时
    local button3, estimatedStr = hs.dialog.textPrompt(
        "编辑任务 - 步骤 3/3",
        "修改预计耗时 (几个E1f):",
        tostring(task.estimatedTime),
        "完成",
        "取消"
    )
    if button3 ~= "完成" then return end

    local newEstimatedTime = tonumber(estimatedStr) or task.estimatedTime
    if newEstimatedTime < 1 then
        newEstimatedTime = 1
    end

    -- 更新任务
    local oldEstimatedTime = task.estimatedTime
    task.name = newName
    task.date = newDate
    task.estimatedTime = newEstimatedTime

    sortTasks()

    -- 重新找到任务索引
    local newIndex = index
    for i, t in ipairs(tasks) do
        if t == task then
            newIndex = i
            break
        end
    end

    -- 如果这是当前任务且预计时间发生了变化，更新倒计时
    if task.id == currentTaskId and oldEstimatedTime ~= newEstimatedTime then
        local countdownMinutes = calculateCountdownTime(task)
        stopCountdown()  -- 先停止当前倒计时
        startCountdown(countdownMinutes)

        hs.notify.new({
            title = "任务已更新",
            informativeText = "预计时间已更新，倒计时重新设置为 " .. countdownMinutes .. " 分钟",
            withdrawAfter = 3
        }):send()
    else
        hs.notify.new({
            title = "任务管理器",
            informativeText = "任务已更新",
            withdrawAfter = 3
        }):send()
    end

    updateMenubar()
    saveTasks()
end

-- 完成任务（逻辑删除）
local function completeTask(index)
    if not tasks[index] or tasks[index].isDone then return end

    local task = tasks[index]
    local button = hs.dialog.blockAlert(
        "完成任务",
        "确定要完成任务 \"" .. task.name .. "\" 吗？",
        "完成",
        "取消"
    )
    if button == "完成" then
        stopTask()
        task.isDone = true
        -- 修改为包含日期的完整时间格式
        task.doneAt = os.date("%Y-%m-%d %H:%M")

        -- 如果这是当前任务，清除当前任务ID
        if task.id == currentTaskId then
            currentTaskId = nil
            -- 尝试选择下一个活跃任务
            local activeTasks = getActiveTasks()
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
        hs.notify.new({
            title = "任务完成",
            informativeText = "任务已完成！评分: " .. calculateScore(task) .. "/5",
            withdrawAfter = 5
        }):send()
    end
end

-- 删除任务（真删除）
local function deleteTask(index)
    if not tasks[index] then return end

    local task = tasks[index]
    local button = hs.dialog.blockAlert(
        "删除任务",
        "确定要删除任务 \"" .. task.name .. "\" 吗？\n注意：此操作不可恢复！",
        "删除",
        "取消"
    )
    if button == "删除" then
        -- 如果删除的是当前任务，停止任务
        if task.id == currentTaskId then
            stopTask()
            currentTaskId = nil
        end

        table.remove(tasks, index)

        -- 尝试选择下一个活跃任务
        if not currentTaskId then
            local activeTasks = getActiveTasks()
            if #activeTasks > 0 then
                currentTaskId = activeTasks[1].task.id
            end
        end

        updateMenubar()
        saveTasks()
        hs.notify.new({
            title = "任务管理器",
            informativeText = "任务已删除",
            withdrawAfter = 3
        }):send()
    end
end

-- 计算当前任务应该启动的倒计时时间
calculateCountdownTime = function(task)
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

-- 选择任务作为当前任务
local function selectTask(index)
    if not tasks[index] or tasks[index].isDone then return end

    -- 如果有正在进行的任务，停止任务
    local currentTask = findTaskById(currentTaskId)
    if currentTask and not currentTask.isDone then
        stopTask()
    end

    currentTaskId = tasks[index].id

    -- 如果任务还没有开始时间，则启动任务
    if not tasks[index].startTime then
        startTask()
    end

    -- 检查是否有保存的倒计时时间（只对已经开始过的任务使用保存的倒计时）
    local taskId = tasks[index].id
    if taskCountdowns[taskId] and taskCountdowns[taskId] > 0 and tasks[index].startTime then
        -- 直接使用保存的剩余秒数
        remainingSeconds = taskCountdowns[taskId]
        isPaused = false

        -- 创建倒计时器
        countdownTimer = hs.timer.doEvery(1, function()
            if not isPaused then
                remainingSeconds = remainingSeconds - 1

                -- 保存当前任务的剩余时间
                if currentTaskId then
                    taskCountdowns[currentTaskId] = remainingSeconds
                end

                updateMenubar()

                if remainingSeconds <= 0 then
                    -- 倒计时结束，自动续期40分钟
                    remainingSeconds = 40 * 60
                    if currentTaskId then
                        taskCountdowns[currentTaskId] = remainingSeconds
                    end

                    sendNotification("⏰ 倒计时结束", "任务时间到！自动续期40分钟", 10, "Glass")

                    updateMenubar()
                end
            end
        end)

        local minutes = math.floor(remainingSeconds / 60)
        local seconds = remainingSeconds % 60
        hs.notify.new({
            title = "恢复任务",
            informativeText = string.format("已恢复: %s (剩余: %d:%02d)", tasks[index].name, minutes, seconds),
            withdrawAfter = 3
        }):send()
    else
        -- 计算新的倒计时时间
        local countdownMinutes = calculateCountdownTime(tasks[index])
        startCountdown(countdownMinutes)
        hs.notify.new({
            title = "当前任务",
            informativeText = "已设置: " .. tasks[index].name .. " (倒计时: " .. countdownMinutes .. "分钟)",
            withdrawAfter = 3
        }):send()
    end
    updateMenubar()
    saveTasks()
end
-- 更新任务实际时间
local function updateTaskActualTime()
    local currentTask = findTaskById(currentTaskId)
    if currentTask and currentTask.startTime then
        local elapsed = os.time() - currentTask.startTime
        currentTask.actualTime = math.floor(elapsed / 60) -- 转换为分钟
        saveTasks()
    end
end

-- 通用导出函数
local function exportTasksForDate(dateStr, dateLabel)
    if not isValidDate(dateStr) then
        hs.notify.new({
            title = "输入错误",
            informativeText = "日期格式错误",
            withdrawAfter = 3
        }):send()
        return
    end

    -- 查找在指定日期完成的任务（按完成时间而不是任务日期）
    local completedTasks = {}
    for _, task in ipairs(tasks) do
        if task.isDone and task.doneAt then
            -- 提取完成日期（doneAt 格式：YYYY-MM-DD HH:MM）
            local completedDate = task.doneAt:match("^(%d%d%d%d%-%d%d%-%d%d)")
            if completedDate == dateStr then
                table.insert(completedTasks, task)
            end
        end
    end

    if #completedTasks == 0 then
        hs.notify.new({
            title = "导出结果",
            informativeText = (dateLabel or dateStr) .. " 没有已完成的任务",
            withdrawAfter = 3
        }):send()
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
        local score = calculateScore(task)
        if score > 0 then
            yaml = yaml .. "      score: " .. score .. "\n"
        end
        yaml = yaml .. "\n"
    end

    -- 复制到剪贴板
    hs.pasteboard.setContents(yaml)
    hs.notify.new({
        title = "导出完成",
        informativeText = "已导出 " .. (dateLabel or dateStr) .. " 的 " .. #completedTasks .. " 个任务到剪贴板",
        withdrawAfter = 5
    }):send()
end

-- 导出本周已完成任务
local function exportThisWeekTasks()
    local mondayStr, todayStr, weekNum = getThisWeekRange()

    -- 查找本周完成的任务
    local completedTasks = {}
    for _, task in ipairs(tasks) do
        if task.isDone and task.doneAt then
            local completedDate = task.doneAt:match("^(%d%d%d%d%-%d%d%-%d%d)")
            if completedDate and completedDate >= mondayStr and completedDate <= todayStr then
                table.insert(completedTasks, task)
            end
        end
    end

    if #completedTasks == 0 then
        hs.notify.new({
            title = "导出结果",
            informativeText = "本周没有已完成的任务",
            withdrawAfter = 3
        }):send()
        return
    end

    -- 按完成时间排序
    table.sort(completedTasks, function(a, b)
        local timeA = a.doneAt or "0000-00-00 00:00"
        local timeB = b.doneAt or "0000-00-00 00:00"
        return timeA < timeB
    end)

    -- 生成YAML格式
    local yaml = "- week: w" .. weekNum .. " " .. mondayStr .. " - " .. todayStr .. "\n  task:\n"
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
        local score = calculateScore(task)
        if score > 0 then
            yaml = yaml .. "      score: " .. score .. "\n"
        end
        yaml = yaml .. "\n"
    end

    -- 复制到剪贴板
    hs.pasteboard.setContents(yaml)
    hs.notify.new({
        title = "导出完成",
        informativeText = "已导出本周的 " .. #completedTasks .. " 个任务到剪贴板",
        withdrawAfter = 5
    }):send()
end

-- 自定义日期导出
local function exportCustomDateTasks()
    local button, dateStr = hs.dialog.textPrompt(
        "导出已完成任务",
        "请输入要导出的日期 (格式: YYYY-MM-DD):",
        getCurrentDate(),
        "导出",
        "取消"
    )
    if button ~= "导出" then return end

    exportTasksForDate(dateStr, nil)
end

-- 创建菜单项
local function createMenu()
    local menu = {}
    local activeTasks = getActiveTasks()

    -- 当前任务显示
    local currentTask = findTaskById(currentTaskId)
    if currentTask and not currentTask.isDone then
        table.insert(menu, {
            title = "当前: " .. currentTask.name,
            disabled = true
        })

        table.insert(menu, { title = "-" })
    end

    -- 按日期分组显示活跃任务
    if #activeTasks > 0 then
        table.insert(menu, {
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
            local dateTitle
            if date == getCurrentDate() then
                dateTitle = "📅 今天"
            else
                dateTitle = "📅 " .. date
            end

            table.insert(menu, {
                title = dateTitle,
                disabled = true
            })

            for _, activeTask in ipairs(tasksByDate[date]) do
                local task = activeTask.task
                local index = activeTask.index
                local prefix = (task.id == currentTaskId) and "● " or "○ "

                -- 使用 UTF-8 安全的字符串截取
                local maxLength = 50
                local displayTask = task.name
                local taskNameLength = 0
                local i = 1
                while i <= string.len(displayTask) do
                    local byteCount = SubStringGetByteCount(displayTask, i)
                    if taskNameLength >= maxLength then
                        displayTask = SubString(displayTask, 1, maxLength - 3) .. "..."
                        break
                    end
                    taskNameLength = taskNameLength + 1
                    i = i + byteCount
                end

                local taskTitle = "  " .. prefix .. displayTask

                table.insert(menu, {
                    title = taskTitle,
                    menu = {
                        {
                            title = "选为当前任务",
                            fn = function() selectTask(index) end
                        },
                        {
                            title = "编辑任务",
                            fn = function() editTask(index) end
                        },
                        {
                            title = "完成任务",
                            fn = function() completeTask(index) end
                        },
                        {
                            title = "删除任务",
                            fn = function() deleteTask(index) end
                        }
                    }
                })
            end
        end
        table.insert(menu, { title = "-" })
    end

    -- 倒计时控制选项
    if countdownTimer and countdownTimer:running() then
        local pauseText = isPaused and "▶️ 恢复倒计时" or "⏸️ 暂停倒计时"
        table.insert(menu, {
            title = pauseText,
            fn = toggleCountdown
        })
        table.insert(menu, { title = "-" })
    end

    -- 操作选项
    table.insert(menu, {
        title = "➕ 添加新任务",
        fn = addTask
    })

    table.insert(menu, {
        title = "📤 导出已完成任务",
        menu = {
            {
                title = "今天 (" .. getCurrentDate() .. ")",
                fn = function() exportTasksForDate(getCurrentDate(), "今天") end
            },
            {
                title = "昨天 (" .. getYesterdayDate() .. ")",
                fn = function() exportTasksForDate(getYesterdayDate(), "昨天") end
            },

            {
--                 title = "本周 (w" .. select(3, getThisWeekRange()) .. " " .. select(1, getThisWeekRange()) .. " - " .. select(2, getThisWeekRange()) .. ")",
                title = "本周",
                fn = exportThisWeekTasks
            },
            {
                title = "自定义",
                fn = exportCustomDateTasks
            },
        }
    })

    table.insert(menu, { title = "-" })

    -- 显示已完成任务数量
    local completedCount = 0
    for _, task in ipairs(tasks) do
        if task.isDone then
            completedCount = completedCount + 1
        end
    end

    if completedCount > 0 then
        table.insert(menu, {
            title = "已完成任务: " .. completedCount,
            disabled = true
        })
        table.insert(menu, { title = "-" })
    end

    table.insert(menu, {
        title = "退出",
        fn = function()
            menubar:delete()
            menubar = nil
        end
    })

    return menu
end

-- 设置菜单
menubar:setMenu(createMenu)

-- 点击菜单栏图标时快速添加任务
menubar:setClickCallback(function()
    addTask()
end)

-- 初始化
loadTasks()
sortTasks()
updateMenubar()

-- 如果有活跃任务但没有当前任务，选择第一个活跃任务
if not currentTaskId then
    local activeTasks = getActiveTasks()
    if #activeTasks > 0 then
        currentTaskId = activeTasks[1].task.id
    end
end

-- 如果有当前任务，启动任务
local currentTask = findTaskById(currentTaskId)
if currentTask and not currentTask.isDone then
    -- 如果任务还没有开始时间，则启动任务
    if not currentTask.startTime then
        startTask()
    end

    -- 启动对应的倒计时
    local countdownMinutes = calculateCountdownTime(currentTask)
    startCountdown(countdownMinutes)
end

-- 设置定时器，每分钟更新一次任务实际时间
local updateTimer = hs.timer.new(60, function()
    updateTaskActualTime()
end)
updateTimer:start()

hs.notify.new({
    title = "任务管理器",
    informativeText = "多任务管理器已启动",
    withdrawAfter = 3
}):send()
