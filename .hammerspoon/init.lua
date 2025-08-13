-- ========================================
-- Hammerspoon 配置文件
-- ========================================

-- 设置日志级别
hs.logger.defaultLogLevel = "info"

-- 启用 IPC 模块以支持命令行控制
hs.ipc = require("hs.ipc")

-- ========================================
-- 加载 Spoons
-- ========================================

-- 音频控制 Spoon
local success1, err1 = pcall(function()
    hs.loadSpoon("AudioControl")
    spoon.AudioControl:start()
end)
if not success1 then
    hs.alert.show("AudioControl 加载失败")
    print("AudioControl 错误:", err1)
end

local success2, err2 = pcall(function()
    hs.loadSpoon("ChromeTabLimit")
    spoon.ChromeTabLimit:start()
end)
if not success2 then
    hs.alert.show("ChromeTabLimit 加载失败")
    print("ChromeTabLimit 错误:", err2)
end


-- 任务列表 Spoon
local success3, err3 = pcall(function()
    hs.loadSpoon("TaskList")
    spoon.TaskList:start()
end)
if not success3 then
    hs.alert.show("TaskList 加载失败")
    print("TaskList 错误:", err3)
end





-- TODO 把指定APP放到指定monitor 的组合动作 [dotfiles/hammerspoon/spectacle.lua at master · rkalis/dotfiles](https://github.com/rkalis/dotfiles/blob/master/hammerspoon/spectacle.lua)


-- ========================================
-- 系统功能
-- ========================================

-- 健康提醒：每40分钟提醒站起来活动
hs.timer.doEvery(40 * 60, function()
    hs.alert.show("站起来活动一下吧！")
end)

-- 安全关机函数（带条件检测）
--function safeShutdown()
--    -- 检测是否有下载任务（扩展更多进程名）
--    local isDownloading = hs.execute("pgrep -x 'curl' || pgrep -x 'wget' || pgrep -x 'aria2c'") ~= ""
--    -- 检测用户空闲时间（单位：秒）
--    local idleTime = hs.idleTime()
--
--    if not isDownloading and idleTime > 600 then  -- 空闲10分钟且无下载
--        hs.execute("sudo shutdown -h now")        -- 立即关机
--    else
--        hs.notify.show("延迟关机", "有任务运行或用户活跃", "")
--    end
--end
--
---- 绑定到每天22:00触发安全关机
--hs.timer.doAt("22:00", safeShutdown)

-- ========================================
-- 配置重载提示
-- ========================================

hs.alert.show("Hammerspoon 配置已重载")
hs.logger.new("init").i("Hammerspoon configuration loaded successfully")
