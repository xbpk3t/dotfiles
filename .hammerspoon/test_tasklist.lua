-- 测试 TaskList Spoon 是否可以正确加载
print("Testing TaskList Spoon loading...")

local success, result = pcall(function()
    local TaskList = hs.loadSpoon("TaskList")
    return TaskList
end)

if success then
    print("✓ TaskList Spoon loaded successfully!")
    print("  Name:", result.name)
    print("  Version:", result.version)
    print("  Author:", result.author)

    -- 测试启动和停止
    local startSuccess, startErr = pcall(function()
        result:start()
        print("✓ TaskList started successfully!")

        -- 等待一秒后停止
        hs.timer.doAfter(1, function()
            result:stop()
            print("✓ TaskList stopped successfully!")
        end)
    end)

    if not startSuccess then
        print("✗ TaskList start failed:", startErr)
    end
else
    print("✗ TaskList Spoon loading failed:", result)
end
