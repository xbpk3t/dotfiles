-- 简化的 Shortcut 测试脚本

-- 测试正确的参数格式
local function testCorrectFormat()
    local minutes = 1
    local seconds = minutes * 60
    local input = string.format("timer\n%d", seconds)

    print("测试正确参数格式:")
    print("输入参数: " .. input)

    -- 使用 shell 命令
    local cmd = string.format('shortcuts run "Shrieking Chimes" --input-text "%s"', input)
    print("执行命令: " .. cmd)

    hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
        print("Shell 结果:")
        print("exitCode:", exitCode)
        print("stdOut:", stdOut or "nil")
        print("stdErr:", stdErr or "nil")

        if exitCode == 0 then
            hs.notify.new({
                title = "Shell 成功",
                informativeText = "倒计时应该已启动",
                withdrawAfter = 3
            }):send()
        else
            -- 尝试 AppleScript
            local script = string.format([[
                tell application "Shortcuts"
                    run shortcut "Shrieking Chimes" with input "%s"
                end tell
            ]], input)

            print("尝试 AppleScript:")
            print(script)

            hs.osascript.applescript(script, function(success, result, descriptor)
                print("AppleScript 结果:")
                print("success:", success)
                print("result:", result or "nil")

                if success then
                    hs.notify.new({
                        title = "AppleScript 成功",
                        informativeText = "倒计时应该已启动",
                        withdrawAfter = 3
                    }):send()
                else
                    hs.notify.new({
                        title = "两种方法都失败",
                        informativeText = "请检查控制台输出",
                        withdrawAfter = 5
                    }):send()
                end
            end)
        end
    end, {"-c", cmd}):start()
end

-- 测试其他可能的格式
local function testAlarmFormat()
    local input = "alarm\n09:11\nHammerspoon Test"

    print("测试 alarm 格式:")
    print("输入参数: " .. input)

    local cmd = string.format('shortcuts run "Shrieking Chimes" --input-text "%s"', input)

    hs.task.new("/bin/sh", function(exitCode, stdOut, stdErr)
        print("Alarm 格式结果:")
        print("exitCode:", exitCode)
        print("stdOut:", stdOut or "nil")
        print("stdErr:", stdErr or "nil")

        hs.notify.new({
            title = "Alarm 格式测试完成",
            informativeText = "exitCode: " .. exitCode,
            withdrawAfter = 3
        }):send()
    end, {"-c", cmd}):start()
end

-- 创建简单的测试菜单
local testMenubar = hs.menubar.new()
testMenubar:setTitle("🧪")

testMenubar:setMenu({
    {
        title = "测试 timer 格式 (1分钟)",
        fn = testCorrectFormat
    },
    {
        title = "测试 alarm 格式",
        fn = testAlarmFormat
    },
    { title = "-" },
    {
        title = "退出测试",
        fn = function()
            testMenubar:delete()
            testMenubar = nil
        end
    }
})

hs.notify.new({
    title = "简化测试工具",
    informativeText = "点击 🧪 测试正确的参数格式",
    withdrawAfter = 3
}):send()

print("简化测试工具已启动")
