--- === TaskList Utils ===
---
--- UTF-8 字符串处理和日期时间工具函数
---

local utils = {}

-- UTF-8 字符串处理函数
--返回截取的实际Index
function utils.SubStringGetTrueIndex(str, index)
    local curIndex = 0
    local i = 1
    local lastCount = 1
    repeat
        lastCount = utils.SubStringGetByteCount(str, i)
        i = i + lastCount
        curIndex = curIndex + 1
    until (curIndex >= index)
    return i - lastCount
end

--返回当前字符实际占用的字符数
function utils.SubStringGetByteCount(str, index)
    local curByte = string.byte(str, index)
    local byteCount = 1
    if curByte == nil then
        byteCount = 0
    elseif curByte > 0 and curByte <= 127 then
        byteCount = 1
    elseif curByte >= 192 and curByte <= 223 then
        byteCount = 2
    elseif curByte >= 224 and curByte <= 239 then
        byteCount = 3
    elseif curByte >= 240 and curByte <= 247 then
        byteCount = 4
    end
    return byteCount
end

--截取中英混合的字符串
function utils.SubString(str, startIndex, endIndex)
    if type(str) ~= "string" then
        return
    end
    if startIndex == nil or startIndex < 0 then
        return
    end

    if endIndex == nil or endIndex < 0 then
        return
    end

    return string.sub(str, utils.SubStringGetTrueIndex(str, startIndex),
            utils.SubStringGetTrueIndex(str, endIndex + 1) - 1)
end

-- 获取当前日期字符串
function utils.getCurrentDate()
    return os.date("%Y-%m-%d")
end

-- 获取昨天日期
function utils.getYesterdayDate()
    return os.date("%Y-%m-%d", os.time() - 24 * 60 * 60)
end

-- 获取指定年份和周数的日期范围
-- year: 年份 (例如: 2025)
-- weekNum: 周数 (0-53)
-- 返回该周的周一和周日日期，以及实际的周数
function utils.getWeekRange(year, weekNum)
    -- 获取该年第一周的周一（第一个周四所在的周）
    local jan1 = os.time({year=year, month=1, day=1, hour=12})
    local jan1Weekday = tonumber(os.date("%w", jan1))

    -- 计算该年的第一个周四
    local firstThursdayOffset = (4 - jan1Weekday - 1 + 7) % 7
    local firstThursday = jan1 + firstThursdayOffset * 24 * 60 * 60

    -- 计算该周四所在周的周一
    local firstMonday = firstThursday - 3 * 24 * 60 * 60

    -- 计算指定周的周一和周日
    local targetMonday = firstMonday + weekNum * 7 * 24 * 60 * 60
    local targetSunday = targetMonday + 6 * 24 * 60 * 60

    local mondayStr = os.date("%Y-%m-%d", targetMonday)
    local sundayStr = os.date("%Y-%m-%d", targetSunday)

    -- 实际周数可能与输入不同，因为ISO周的计算方式
    local actualWeekNum = tonumber(os.date("%W", targetMonday))

    return mondayStr, sundayStr, actualWeekNum
end

-- 获取相对于当前周的日期范围
-- offset: 相对于当前周的偏移量，例如：
--   0 表示当前周
--  -1 表示上周
--  -2 表示上上周
--   1 表示下周
--   2 表示下下周
-- 以此类推
function utils.getRelativeWeekRange(offset)
    offset = offset or 0
    local today = os.time()
    local todayWeekday = tonumber(os.date("%w", today)) -- 0=Sunday, 1=Monday, ...

    -- 计算本周一的日期
    local mondayOffset = (todayWeekday == 0) and 6 or (todayWeekday - 1)
    local thisMonday = today - mondayOffset * 24 * 60 * 60

    -- 计算目标周的周一
    local targetMonday = thisMonday + offset * 7 * 24 * 60 * 60

    -- 计算目标周的周日
    local targetSunday = targetMonday + 6 * 24 * 60 * 60

    local mondayStr = os.date("%Y-%m-%d", targetMonday)
    local sundayStr = os.date("%Y-%m-%d", targetSunday)
    local weekNum = tonumber(os.date("%W", targetMonday))
    local year = tonumber(os.date("%Y", targetMonday))

    return mondayStr, sundayStr, weekNum, year
end

-- 获取当前时间字符串
function utils.getCurrentTime()
    return os.date("%H:%M")
end

-- 验证日期格式
function utils.isValidDate(dateStr)
    if not dateStr then return false end
    local year, month, day = dateStr:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
    if not year then return false end
    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    if not year or not month or not day then return false end
    if month < 1 or month > 12 then return false end
    if day < 1 or day > 31 then return false end
    return true
end

-- 简单的字符串hash函数
function utils.simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) % 2147483647
    end
    return hash
end

-- 生成任务ID的函数（hash(添加时间戳 + 任务内容)）
function utils.generateTaskId(addTime, taskName, date, estimatedTime)
    local content = tostring(addTime) .. "|" .. taskName .. "|" .. date .. "|" .. tostring(estimatedTime)
    return tostring(utils.simpleHash(content))
end

-- 清理字符串，将多行字符串转换为单行，处理特殊字符
function utils.sanitizeString(str)
    if type(str) ~= "string" then
        return str
    end

    -- 替换换行符为空格
    str = str:gsub("[\r\n]+", " ")

    -- 替换制表符为空格
    str = str:gsub("\t", " ")

    -- 处理其他可能导致JSON解析问题的控制字符
    str = str:gsub("[\001-\031\127]", " ")

    -- 处理连续的空格
    str = str:gsub("%s+", " ")

    -- 去除首尾空格
    str = str:match("^%s*(.-)%s*$")

    return str
end

-- 为JSON导出清理任务名称
function utils.sanitizeTaskName(taskName)
    if type(taskName) ~= "string" then
        return taskName
    end

    -- 使用sanitizeString处理基本的多行和特殊字符
    local cleaned = utils.sanitizeString(taskName)

    -- 额外处理JSON中的特殊字符
    cleaned = cleaned:gsub('\\', '\\\\')  -- 转义反斜杠
    cleaned = cleaned:gsub('"', '\\"')    -- 转义双引号

    return cleaned
end

return utils
