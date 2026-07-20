--- === Shared Limit Alerts ===
---
--- ChromeTabLimit / ClaudeSessionLimit 共用节拍与超限 alert 时长
--- init.lua 用 checkInterval 驱动共享 timer；两边 notifs 用 limitAlertDuration

return {
  --- 共享检查间隔（秒）
  checkInterval = 30,
  --- 超限 compact alert 存留秒数（两边必须一致）
  --- 对齐 Chrome 改 alert 后的 tabLimitExceeded：notifs.show(message, 5)
  --- （更早的 notification 时代曾用 withdrawAfter=0，不是当前 alert 行为）
  limitAlertDuration = 5,
  --- enable / disable / status 等短提示
  shortAlertDuration = 3,
}
