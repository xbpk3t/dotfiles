--- === TaskDialog ===
---
--- 简化的任务创建/编辑对话框
--- 使用原生 Hammerspoon 对话框，避免 WebView 的复杂性
---

local taskDialog = {}
local utils = dofile(hs.configdir .. "/Spoons/TaskList.spoon/utils.lua")

-- 显示任务对话框
function taskDialog.showDialog(title, task, isEdit, callback)
    -- 使用多步骤的原生对话框

    -- 第一步：任务名称
    local button1, taskName = hs.dialog.textPrompt(
        isEdit and "编辑任务 - 任务名称" or "添加新任务 - 任务名称",
        "请输入任务名称:",
        task and task.name or "",
        "下一步",
        "取消"
    )
    if button1 ~= "下一步" or not taskName or taskName == "" then
        if callback then callback({action = "cancel"}) end
        return
    end

    -- 第二步：日期
    local button2, dateStr = hs.dialog.textPrompt(
        isEdit and "编辑任务 - 日期" or "添加新任务 - 日期",
        "请输入日期 (格式: YYYY-MM-DD):",
        task and task.date or utils.getCurrentDate(),
        "下一步",
        "取消"
    )
    if button2 ~= "下一步" then
        if callback then callback({action = "cancel"}) end
        return
    end

    if not utils.isValidDate(dateStr) then
        hs.alert.show("日期格式错误，请使用 YYYY-MM-DD 格式")
        if callback then callback({action = "cancel"}) end
        return
    end

    -- 第三步：预计耗时
    local button3, estimatedStr = hs.dialog.textPrompt(
        isEdit and "编辑任务 - 预计耗时" or "添加新任务 - 预计耗时",
        "请输入预计耗时 (几个E1f，每个E1f=40分钟):",
        task and tostring(task.estimatedTime) or "1",
        "下一步",
        "取消"
    )
    if button3 ~= "下一步" then
        if callback then callback({action = "cancel"}) end
        return
    end

    local estimatedTime = tonumber(estimatedStr) or 1
    if estimatedTime < 1 then
        estimatedTime = 1
    end

    local review = ""

    -- 第四步：复盘总结（仅在编辑时显示）
    if isEdit then
        local button4, reviewInput = hs.dialog.textPrompt(
            "编辑任务 - 复盘总结",
            "请输入复盘总结（可选）:",
            task and task.review or "",
            "完成",
            "取消"
        )
        if button4 ~= "完成" then
            if callback then callback({action = "cancel"}) end
            return
        end
        review = reviewInput or ""
    end

    -- 提交结果
    if callback then
        callback({
            action = "submit",
            data = {
                taskName = taskName,
                taskDate = dateStr,
                estimatedTime = estimatedTime,
                review = review
            }
        })
    end
end

return taskDialog
