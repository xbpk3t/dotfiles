--- === Shared Alerts ===
---
--- 统一 alert 系统。所有 Spoon 的 hs.alert 走这里，确保:
--- - 风格一致（compact 12pt，不污染 hs.alert.defaultStyle）
--- - 颜色分级（成功绿 / 错误红 / 信息灰 / 默认无偏移）
--- - 异常隔离（pcall 包裹，不回抛）

local alerts = {}

-- ====================================================================
-- 私有：风格定义
-- ====================================================================

-- 基础 compact 风格（从全局默认 copy，不改原始对象）
local COMPACT_STYLE = hs.fnutils.copy(hs.alert.defaultStyle)
COMPACT_STYLE.textSize = 12
COMPACT_STYLE.radius = 8

-- 分级风格（从 COMPACT_STYLE 继承，只改 fillColor）
local SUCCESS_STYLE = hs.fnutils.copy(COMPACT_STYLE)
SUCCESS_STYLE.fillColor = { red = 0.12, green = 0.48, blue = 0.22, alpha = 0.90 }

local ERROR_STYLE = hs.fnutils.copy(COMPACT_STYLE)
ERROR_STYLE.fillColor = { red = 0.62, green = 0.16, blue = 0.16, alpha = 0.92 }

local INFO_STYLE = hs.fnutils.copy(COMPACT_STYLE)
INFO_STYLE.fillColor = { red = 0.18, green = 0.18, blue = 0.22, alpha = 0.88 }

local DEFAULT_DURATION = 3

-- ====================================================================
-- 私有：核心显示
-- ====================================================================

local function _show(text, style, screen, duration)
  if not text or text == "" then
    return nil
  end
  local ok, id = pcall(hs.alert.show, text, style or COMPACT_STYLE, screen, duration or DEFAULT_DURATION)
  if not ok then
    print(string.format("Alert 显示失败: %s", tostring(text)))
    return nil
  end
  return id
end

-- ====================================================================
-- 公共 API：按用途分类
-- ====================================================================

--- alerts.show(text, duration?, screen?)
--- 默认 compact alert（无颜色偏移）
function alerts.show(text, duration, screen)
  return _show(text, COMPACT_STYLE, screen, duration)
end

--- alerts.success(text, duration?, screen?)
--- 绿色底，操作成功时使用
function alerts.success(text, duration, screen)
  return _show(text, SUCCESS_STYLE, screen, duration)
end

--- alerts.error(text, duration?, screen?)
--- 红色底，操作失败或错误时使用
function alerts.error(text, duration, screen)
  return _show(text, ERROR_STYLE, screen, duration)
end

--- alerts.info(text, duration?, screen?)
--- 灰色底，中性信息提示
function alerts.info(text, duration, screen)
  return _show(text, INFO_STYLE, screen, duration)
end

-- ====================================================================
-- 兼容别名（供旧代码逐步迁移）
-- ====================================================================

alerts.showAlert = alerts.show
alerts.showDefault = alerts.show
alerts.showSuccess = alerts.success
alerts.showError = alerts.error
alerts.showInfo = alerts.info

-- ====================================================================
-- 工具函数
-- ====================================================================

function alerts.closeSpecific(id)
  if not id then
    return
  end
  pcall(hs.alert.closeSpecific, id)
end

function alerts.closeAll()
  pcall(hs.alert.closeAll)
end

return alerts
