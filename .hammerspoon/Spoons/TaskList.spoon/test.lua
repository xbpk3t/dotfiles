#!/usr/bin/env lua

-- 模拟 Hammerspoon 环境
local hs = {
    configdir = ".hammerspoon",
    logger = {
        new = function(name)
            return {
                i = function(msg) print("[INFO] " .. msg) end,
                e = function(msg) print("[ERROR] " .. msg) end
            }
        end
    },
    timer = {
        secondsSinceEpoch = function() return os.time() end,
        new = function(interval, fn) return {start = function() end, stop = function() end} end,
        doEvery = function(interval, fn) return {running = function() return false end, stop = function() end} end
    },
    json = {
        encode = function(data) return "mock_json" end,
        decode = function(str) return {} end
    },
    notify = {
        new = function(opts) return {send = function() end, soundName = function() end} end
    },
    dialog = {
        textPrompt = function() return "取消", "" end,
        blockAlert = function() return "取消" end
    },
    menubar = {
        new = function() return {setMenu = function() end, setTitle = function() end, setClickCallback = function() end, delete = function() end} end
    },
    styledtext = {
        new = function(text, style) return text end
    },
    pasteboard = {
        setContents = function(content) print("Clipboard: " .. content) end
    },
    spoons = {
        bindHotkeysToSpec = function() end
    },
    mouse = {
        absolutePosition = function() return {x=0, y=0} end
    }
}

-- 设置全局 hs 对象
_G.hs = hs

-- 测试模块加载
print("Testing TaskList Spoon modules...")

local spoonPath = ".hammerspoon/Spoons/TaskList.spoon"

-- 测试各个模块
local success, err

success, err = pcall(function()
    local utils = dofile(spoonPath .. "/utils.lua")
    print("✓ utils.lua loaded successfully")
    print("  getCurrentDate:", utils.getCurrentDate())
    print("  isValidDate('2024-01-01'):", utils.isValidDate('2024-01-01'))
end)
if not success then print("✗ utils.lua failed:", err) end

success, err = pcall(function()
    local notifications = dofile(spoonPath .. "/notifications.lua")
    print("✓ notifications.lua loaded successfully")
end)
if not success then print("✗ notifications.lua failed:", err) end

success, err = pcall(function()
    local scoring = dofile(spoonPath .. "/scoring.lua")
    print("✓ scoring.lua loaded successfully")
end)
if not success then print("✗ scoring.lua failed:", err) end

success, err = pcall(function()
    local data = dofile(spoonPath .. "/data.lua")
    print("✓ data.lua loaded successfully")
end)
if not success then print("✗ data.lua failed:", err) end

success, err = pcall(function()
    local tasks = dofile(spoonPath .. "/tasks.lua")
    print("✓ tasks.lua loaded successfully")
end)
if not success then print("✗ tasks.lua failed:", err) end

success, err = pcall(function()
    local countdown = dofile(spoonPath .. "/countdown.lua")
    print("✓ countdown.lua loaded successfully")
end)
if not success then print("✗ countdown.lua failed:", err) end

success, err = pcall(function()
    local export = dofile(spoonPath .. "/export.lua")
    print("✓ export.lua loaded successfully")
end)
if not success then print("✗ export.lua failed:", err) end

success, err = pcall(function()
    local menu = dofile(spoonPath .. "/menu.lua")
    print("✓ menu.lua loaded successfully")
end)
if not success then print("✗ menu.lua failed:", err) end

-- 测试主 init.lua
success, err = pcall(function()
    local TaskList = dofile(spoonPath .. "/init.lua")
    print("✓ init.lua loaded successfully")
    print("  Spoon name:", TaskList.name)
    print("  Spoon version:", TaskList.version)
end)
if not success then print("✗ init.lua failed:", err) end

print("\nAll tests completed!")
