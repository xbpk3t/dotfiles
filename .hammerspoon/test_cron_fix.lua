-- 测试 CronTask 修复的验证脚本
-- 在 Hammerspoon 控制台中运行: dofile(hs.configdir .. "/test_cron_fix.lua")

local spoonPath = hs.configdir .. "/Spoons/TaskList.spoon"
local cronTask = dofile(spoonPath .. "/cron_task.lua")

print("=== CronTask 修复验证 ===")

-- 测试当前时间的 CronTask 过滤
print("1. 测试 CronTask 过滤逻辑:")
local cronTaskFilePath = spoonPath .. "/CronTask.yml"
local cronTasks = cronTask.parseCronTaskFile(cronTaskFilePath)
print("解析到的 CronTask 类型数量:", #cronTasks)

local filteredCronTasks = cronTask.filterCronTasks(cronTasks)
print("当前应该显示的任务数量:", #filteredCronTasks)

for i, task in ipairs(filteredCronTasks) do
    print(string.format("  %d. %s - %s", i, task.type, task.task))
end

-- 测试转换为 TaskList 格式
print("\n2. 测试转换为 TaskList 格式:")
local taskListTasks = cronTask.convertToTaskListFormat(filteredCronTasks)
print("转换后的任务数量:", #taskListTasks)

for i, task in ipairs(taskListTasks) do
    print(string.format("  %d. %s (ID: %s, Date: %s)", i, task.name, task.id, task.date))
end

-- 测试 ID 幂等性
if #taskListTasks > 0 then
    print("\n3. 测试 ID 幂等性:")
    local firstTask = taskListTasks[1]
    hs.timer.usleep(1000) -- 等待1毫秒
    local taskListTasks2 = cronTask.convertToTaskListFormat(filteredCronTasks)
    local secondTask = taskListTasks2[1]

    print("第一次 ID:", firstTask.id)
    print("第二次 ID:", secondTask.id)
    print("ID 相同:", firstTask.id == secondTask.id)
end

print("\n=== 验证完成 ===")
