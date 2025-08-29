-- 测试通知系统修复
print("=== 测试通知系统修复 ===")

-- 模拟 Hammerspoon 环境
_G.hs = {
    notify = {
        new = function(opts)
            print("创建通知:", opts.title, "-", opts.informativeText)
            return {
                soundName = function(self, sound)
                    print("设置音效:", sound)
                    return self
                end,
                send = function(self)
                    print("发送通知成功")
                    return true
                end
            }
        end
    },
    configdir = "/Users/lhgtqb7bll/Desktop/dotfiles/.hammerspoon"
}

print("\n1. 测试底层 notifications.lua...")
local success1, baseNotifications = pcall(function()
    return dofile("./.hammerspoon/Spoons/TaskList.spoon/notifications.lua")
end)
if success1 then
    print("✅ 底层 notifications.lua 加载成功")
    local defaults = baseNotifications.getDefaults()
    print("   默认配置:", "withdrawAfter=" .. defaults.withdrawAfter, "successSound=" .. defaults.successSound)
else
    print("❌ 底层 notifications.lua 加载失败:", baseNotifications)
end

print("\n2. 测试 AudioControl notifications.lua...")
local success2, audioNotifications = pcall(function()
    return dofile("./.hammerspoon/Spoons/AudioControl.spoon/notifications.lua")
end)
if success2 then
    print("✅ AudioControl notifications.lua 加载成功")
else
    print("❌ AudioControl notifications.lua 加载失败:", audioNotifications)
end

print("\n3. 测试 ChromeTabLimit notifications.lua...")
local success3, chromeNotifications = pcall(function()
    return dofile("./.hammerspoon/Spoons/ChromeTabLimit.spoon/notifications.lua")
end)
if success3 then
    print("✅ ChromeTabLimit notifications.lua 加载成功")
else
    print("❌ ChromeTabLimit notifications.lua 加载失败:", chromeNotifications)
end

print("\n4. 测试 TaskList tasklist_notifications.lua...")
local success4, tasklistNotifications = pcall(function()
    return dofile("./.hammerspoon/Spoons/TaskList.spoon/tasklist_notifications.lua")
end)
if success4 then
    print("✅ TaskList tasklist_notifications.lua 加载成功")
else
    print("❌ TaskList tasklist_notifications.lua 加载失败:", tasklistNotifications)
end

print("\n=== 测试完成 ===")
if success1 and success2 and success3 and success4 then
    print("🎉 所有通知模块加载成功！C栈溢出问题已修复。")
else
    print("⚠️  某些模块仍有问题，请检查错误信息。")
end
