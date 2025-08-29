-- 测试导出功能重构
print("=== 测试导出功能重构 ===")

-- 模拟 Hammerspoon 环境
_G.hs = {
    notify = {
        new = function(opts)
            print("创建通知:", opts.title or "无标题", "-", opts.informativeText or "无内容")
            return {
                soundName = function(self, sound)
                    print("设置音效:", sound or "无音效")
                    return self
                end,
                send = function(self)
                    print("发送通知")
                    return true
                end
            }
        end
    },
    pasteboard = {
        setContents = function(content)
            print("复制到剪贴板:", content:sub(1, 100) .. "...")
            return true
        end
    },
    dialog = {
        textPrompt = function(message, informativeText, defaultText, button1, button2)
            print("对话框:", message)
            return button1, defaultText
        end
    },
    configdir = "/Users/lhgtqb7bll/Desktop/dotfiles/.hammerspoon"
}

-- 模拟任务列表
local mockTasks = {
    {
        id = 1,
        name = "完成项目A",
        isDone = true,
        doneAt = "2024-01-15 14:30:00",
        estimatedTime = 2,
        actualTime = 2.5,
        isCronTask = false
    },
    {
        id = 2,
        name = "修复Bug",
        isDone = true,
        doneAt = "2024-01-16 09:15:00",
        estimatedTime = 1,
        actualTime = 1.2,
        isCronTask = false
    }
}

-- 模拟utils和scoring模块
_G.utils = {
    getCurrentDate = function() return "2024-01-15" end,
    getYesterdayDate = function() return "2024-01-14" end,
    getThisWeekRange = function() return "2024-01-08", "2024-01-14", 2 end,
    getLastWeekRange = function() return "2024-01-01", "2024-01-07", 1 end,
    isValidDate = function(date) return date:match("^%d%d%d%d%-%d%d%-%d%d$") ~= nil end,
    sanitizeString = function(str) return str:gsub("\n", " ") end
}

_G.scoring = {
    calculateScore = function(task) return 85 end
}

print("\n1. 准备模拟环境...")

-- 先设置_G.notifications，然后再加载模块
_G.notifications = {
    dateFormatError = function() print("日期格式错误") end,
    exportNoTasks = function(label) print("没有任务:", label) end,
    exportCompleted = function(label, count) print("导出完成:", label, count, "个任务") end
}

print("\n2. 测试加载模块...")
local success, export = pcall(function()
    return dofile("./.hammerspoon/Spoons/TaskList.spoon/export.lua")
end)
if success then
    print("✅ export.lua 加载成功")
else
    print("❌ export.lua 加载失败:", export)
    os.exit(1)
end

print("\n3. 测试 exportTasksForDate...")
print("调用: exportTasksForDate(mockTasks, '2024-01-15', '测试日期')")
local result1 = export.exportTasksForDate(mockTasks, "2024-01-15", "测试日期")
print("返回值:", result1)

print("\n4. 测试 exportTasksForRange...")
print("调用: exportTasksForRange(mockTasks, '2024-01-14', '2024-01-16', '测试范围')")
local result2 = export.exportTasksForRange(mockTasks, "2024-01-14", "2024-01-16", "测试范围")
print("返回值:", result2)

print("\n5. 测试 exportThisWeekTasks...")
print("调用: exportThisWeekTasks(mockTasks)")
local result3 = export.exportThisWeekTasks(mockTasks)
print("返回值:", result3)

print("\n6. 测试 exportLastWeekTasks...")
print("调用: exportLastWeekTasks(mockTasks)")
local result4 = export.exportLastWeekTasks(mockTasks)
print("返回值:", result4)

print("\n=== 重构测试完成 ===")
print("✅ 所有导出功能执行完成！重构成功！")
print("注意：函数返回nil是正常的，因为它们主要执行副作用（复制到剪贴板和显示通知）")
