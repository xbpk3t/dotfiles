--- === TaskList Scoring ===
---
--- 任务评分计算系统
---

local scoring = {}

-- 计算评分 (1-5分，整数制)
function scoring.calculateScore(task)
    if not task.isDone or task.estimatedTime == 0 then
        return 0
    end

    local timeRatio = task.actualTime / (task.estimatedTime * 40) -- 40分钟为一个单位
    local baseScore = 3 -- 基础分数

    -- 1. 时间效率评分 (权重: 60%)
    local timeScore = 0
    if timeRatio <= 0.5 then
        timeScore = 2  -- 极快完成 (5分)
    elseif timeRatio <= 0.8 then
        timeScore = 1  -- 提前完成 (4分)
    elseif timeRatio <= 1.0 then
        timeScore = 0  -- 按时完成 (3分)
    elseif timeRatio <= 1.2 then
        timeScore = -1 -- 轻微超时 (2分)
    elseif timeRatio <= 1.5 then
        timeScore = -2 -- 中度超时 (1分)
    elseif timeRatio <= 2.0 then
        timeScore = -2 -- 严重超时 (1分)
    else
        timeScore = -2 -- 极度超时 (1分)
    end

    -- 2. 任务复杂度评分 (权重: 20%)
    local complexityBonus = 0
    if task.estimatedTime >= 3 then
        complexityBonus = 1  -- 复杂任务完成加分
    elseif task.estimatedTime >= 2 then
        complexityBonus = 0  -- 中等任务无加分
    else
        complexityBonus = 0  -- 简单任务无加分
    end

    -- 3. 完成时间评分 (权重: 10%)
    local timeOfDayBonus = 0
    if task.doneAt then
        local hour = tonumber(task.doneAt:match("(%d%d):"))
        if hour and hour >= 9 and hour <= 18 then
            timeOfDayBonus = 0  -- 工作时间完成，无额外加分
        elseif hour and (hour >= 19 and hour <= 22) then
            timeOfDayBonus = 0  -- 晚上完成，无额外加分
        else
            timeOfDayBonus = -1 -- 深夜或早晨完成，扣分
        end
    end

    -- 4. 任务及时性评分 (权重: 10%)
    local timelinessBonus = 0
    if task.date and task.doneAt then
        local taskDate = task.date
        local doneDate = task.doneAt:match("^(%d%d%d%d%-%d%d%-%d%d)")
        if doneDate == taskDate then
            timelinessBonus = 0  -- 当天完成，无额外加分
        elseif doneDate > taskDate then
            timelinessBonus = -1 -- 延期完成，扣分
        else
            timelinessBonus = 1  -- 提前完成，加分
        end
    end

    -- 综合计算最终分数
    local finalScore = baseScore + timeScore + complexityBonus + timeOfDayBonus + timelinessBonus

    -- 确保分数在1-5范围内
    finalScore = math.max(1, math.min(5, finalScore))

    -- 返回整数分数
    return math.floor(finalScore + 0.5)
end

return scoring
