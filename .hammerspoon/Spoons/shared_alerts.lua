--- === Shared Base Alerts ===
---
--- 全局底层 alert 系统处理模块
--- 提供基础的 alert 显示功能，供各个 Spoon 的包装器复用
---

local alerts = {}

-- 默认配置
local DEFAULT_DURATION = 3

local DEFAULT_STYLE = hs.alert.defaultStyle
local SUCCESS_STYLE = hs.fnutils.copy(DEFAULT_STYLE)
local ERROR_STYLE = hs.fnutils.copy(DEFAULT_STYLE)
local INFO_STYLE = hs.fnutils.copy(DEFAULT_STYLE)

-- 轻量区分严重级别，避免影响可读性
SUCCESS_STYLE.fillColor = { red = 0.12, green = 0.48, blue = 0.22, alpha = 0.9 }
ERROR_STYLE.fillColor = { red = 0.62, green = 0.16, blue = 0.16, alpha = 0.92 }
INFO_STYLE.fillColor = { red = 0.18, green = 0.18, blue = 0.22, alpha = 0.88 }

-- 私有函数：核心 alert 显示逻辑
local function _showAlert(text, duration, style, screen)
    duration = duration
    if duration == nil then
        duration = DEFAULT_DURATION
    end

    local ok, id = pcall(function()
        return hs.alert.show(text or "", style or DEFAULT_STYLE, screen, duration)
    end)

    if not ok then
        print("Alert 显示失败: " .. tostring(text))
        print("⚠ " .. tostring(text))
        return nil
    end

    return id
end

-- 公共 API：显示基础 alert
function alerts.showAlert(text, duration, style, screen)
    return _showAlert(text, duration, style, screen)
end

-- 显示默认 alert
function alerts.showDefault(text, duration, screen)
    return _showAlert(text, duration, DEFAULT_STYLE, screen)
end

-- 显示成功 alert
function alerts.showSuccess(text, duration, screen)
    return _showAlert(text, duration, SUCCESS_STYLE, screen)
end

-- 显示错误 alert
function alerts.showError(text, duration, screen)
    return _showAlert(text, duration, ERROR_STYLE, screen)
end

-- 显示信息 alert
function alerts.showInfo(text, duration, screen)
    return _showAlert(text, duration, INFO_STYLE, screen)
end

-- 关闭指定 alert
function alerts.closeSpecific(id)
    if not id then
        return
    end
    pcall(function()
        hs.alert.closeSpecific(id)
    end)
end

-- 关闭全部 alert
function alerts.closeAll()
    pcall(function()
        hs.alert.closeAll()
    end)
end

-- 获取默认配置（供其他模块使用）
function alerts.getDefaults()
    return {
        duration = DEFAULT_DURATION,
        defaultStyle = DEFAULT_STYLE,
        successStyle = SUCCESS_STYLE,
        errorStyle = ERROR_STYLE,
        infoStyle = INFO_STYLE
    }
end

return alerts
