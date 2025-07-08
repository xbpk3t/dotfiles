require "modules/bluetooth"
local wifiAudio = require("modules/mute")

local tasklist = require("modules/tasklist")
-- local shortcut = require("modules/test_shortcut")

hs.timer.doEvery(40 * 60, function()
    hs.alert.show("站起来活动一下吧！")
end)

-- 安全关机函数（带条件检测）
function safeShutdown()
    -- 检测是否有下载任务（扩展更多进程名）
    local isDownloading = hs.execute("pgrep -x 'curl' || pgrep -x 'wget' || pgrep -x 'aria2c'") ~= ""
    -- 检测用户空闲时间（单位：秒）
    local idleTime = hs.idleTime()

    if not isDownloading and idleTime > 600 then  -- 空闲10分钟且无下载
        hs.execute("sudo shutdown -h now")        -- 立即关机
    else
        hs.notify.show("延迟关机", "有任务运行或用户活跃", "")
    end
end

-- 绑定到每天22:00触发
hs.timer.doAt("22:00", safeShutdown)
