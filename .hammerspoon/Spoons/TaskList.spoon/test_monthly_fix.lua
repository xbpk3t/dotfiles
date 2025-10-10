-- 测试脚本：验证月度任务的ID生成是否幂等
local spoonPath = hs.configdir .. "/Spoons/TaskList.spoon"
local cronTask = dofile(spoonPath .. "/cron_task.lua")
local utils = dofile(spoonPath .. "/utils.lua")

-- 模拟 3monthly 任务
local testCronTask = {
    type = "@3monthly",
    task = "【每月消费复盘】"
}

-- 模拟转换过程
print("=== 测试月度任务ID生成的幂等性 ===")

-- 第一次生成
local taskName1 = testCronTask.type .. " " .. testCronTask.task
local taskDate1, addTime1 = calculateCronTaskDateTime(testCronTask.type)
local taskId1 = utils.generateTaskId(addTime1, taskName1, taskDate1, 1)

print("第一次生成：")
print("  任务名称: " .. taskName1)
print("  任务日期: " .. taskDate1)
print("  添加时间: " .. addTime1)
print("  任务ID: " .. taskId1)

-- 等待1秒
hs.timer.usleep(1000000)

-- 第二次生成
local taskName2 = testCronTask.type .. " " .. testCronTask.task
local taskDate2, addTime2 = calculateCronTaskDateTime(testCronTask.type)
local taskId2 = utils.generateTaskId(addTime2, taskName2, taskDate2, 1)

print("\n第二次生成：")
print("  任务名称: " .. taskName2)
print("  任务日期: " .. taskDate2)
print("  添加时间: " .. addTime2)
print("  任务ID: " .. taskId2)

print("\n=== 结果 ===")
print("任务ID是否相同: " .. (taskId1 == taskId2 and "是" or "否"))
print("添加时间是否相同: " .. (addTime1 == addTime2 and "是" or "否"))
print("任务日期是否相同: " .. (taskDate1 == taskDate2 and "是" or "否"))

if taskId1 == taskId2 then
    print("✅ 修复成功！月度任务ID现在是幂等的")
else
    print("❌ 修复失败！任务ID仍然不一致")
end
