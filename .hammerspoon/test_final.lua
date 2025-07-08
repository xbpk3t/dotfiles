-- 最终测试脚本
print("=== 最终 Spoons 测试 ===")

-- 停止现有的 Spoons（如果有的话）
if spoon.TaskList then
    spoon.TaskList:stop()
end

-- 重新加载 TaskList
local success, err = pcall(function()
    hs.loadSpoon("TaskList")
    spoon.TaskList:start()
end)

if success then
    print("✅ TaskList 重新加载成功")

    -- 测试菜单创建
    local menuSuccess, menuErr = pcall(function()
        if spoon.TaskList and spoon.TaskList.menubar then
            print("✅ MenuBar 创建成功")
        else
            print("⚠️  MenuBar 状态未知")
        end
    end)

    if not menuSuccess then
        print("❌ MenuBar 测试失败:", menuErr)
    end

else
    print("❌ TaskList 加载失败:", err)
end

print("=== 测试完成 ===")
