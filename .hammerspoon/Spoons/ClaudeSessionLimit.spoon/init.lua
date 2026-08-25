--- === ClaudeSessionLimit ===
---
--- 监控 Claude Code 活跃 session 数量，超出限制时 compact alert（仅提醒）
--- 计数权威：herdr 原生 `agent list`（跨 workspace，且可经 --remote 覆盖远端 herdr server）
--- 无 herdr 场景下计数为 0（不弹）

local obj = {}
obj.__index = obj

obj.name = "ClaudeSessionLimit"
obj.version = "1.0.1"
obj.author = "luck"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new("ClaudeSessionLimit")

--- 是否启用
obj.enabled = true
--- 最大 interactive session 数
obj.maxSessions = 25
--- 检查间隔（秒）；status 展示用，实际节拍由 init 共享 coordinator 驱动
obj.checkInterval = 30
--- herdr CLI（绝对路径）
obj.herdrBin = "/etc/profiles/per-user/luck/bin/herdr"
--- 远端 herdr server 目标列表（`herdr --remote <t> agent list`）；空 = 只查本机
obj.remoteTargets = {} -- e.g. {"user@host1"}

local notifs = dofile(hs.configdir .. "/Spoons/ClaudeSessionLimit.spoon/notifs.lua")

--- 对单个 herdr target（nil = 本机 server）跑 `agent list`，返回 agent==claude 的条数。
--- 返回 nil 表示该次查询失败（server 未起 / 目标不可达），由调用方决定累计策略。
local function countClaudeFromHerdr(target)
  local cmd
  if target and target ~= "" then
    cmd = string.format("%s --remote '%s' agent list 2>/dev/null", obj.herdrBin, target)
  else
    cmd = obj.herdrBin .. " agent list 2>/dev/null"
  end

  local output, ok = hs.execute(cmd)
  if not ok or not output or output == "" then
    obj.logger.w("herdr agent list failed" .. (target and (" target=" .. target) or ""))
    return nil
  end

  local decodedArr, data = pcall(hs.json.decode, output)
  if not decodedArr or type(data) ~= "table" then
    obj.logger.w("failed to parse herdr agent list output" .. (target and (" target=" .. target) or ""))
    return nil
  end

  local agents = (data.result and type(data.result) == "table" and data.result.agents) or data.agents
  if type(agents) ~= "table" then
    obj.logger.w("herdr agent list: no agents array")
    return nil
  end

  local count = 0
  for _, a in ipairs(agents) do
    if type(a) == "table" and a.agent == "claude" then
      count = count + 1
    end
  end
  return count
end

--- 汇总：本机 + 各 remote target 的 claude session 数。
--- 本机查询失败视为 0；某个 remote 查询失败记 log 但计入 0（不拖垮整体）。
local function getInteractiveSessionCount()
  local total = 0

  local localCount = countClaudeFromHerdr(nil)
  if localCount ~= nil then
    total = localCount
  else
    obj.logger.w("unable to count local herdr agents; treating as 0")
  end

  for _, target in ipairs(obj.remoteTargets or {}) do
    local rc = countClaudeFromHerdr(target)
    if rc ~= nil then
      total = total + rc
    else
      obj.logger.w("unable to count remote herdr agents target=" .. tostring(target) .. "; treating as 0")
    end
  end

  obj.logger.d("claude agent total(" .. #(obj.remoteTargets or {}) .. " remote)=" .. total)
  return total
end

local function checkSessionLimit()
  if not obj.enabled then
    return
  end

  local n = getInteractiveSessionCount()
  if n > obj.maxSessions then
    local excess = n - obj.maxSessions
    notifs.sessionLimitExceeded(n, obj.maxSessions, excess)
    obj.logger.w(string.format("limit exceeded: current=%d max=%d excess=%d", n, obj.maxSessions, excess))
  end
end

--- 立即检查（共享 coordinator / 热键）
function obj:checkNow()
  checkSessionLimit()
  return self
end

function obj:start()
  if not self.enabled then
    self.logger.i("disabled, not starting")
    return self
  end

  self.logger.i("started maxSessions=" .. self.maxSessions)
  return self
end

function obj:stop()
  self.logger.i("stopped")
  return self
end

function obj:toggle()
  if self.enabled then
    self:stop()
    self.enabled = false
    notifs.disabled()
    self.logger.i("disabled")
  else
    self.enabled = true
    self:start()
    notifs.enabled()
    self.logger.i("enabled")
  end
  return self
end

--- 供 console / 测试：返回当前 interactive 计数
function obj:getCount()
  return getInteractiveSessionCount()
end

function obj:getStatus()
  local remoteCount = #(self.remoteTargets or {})
  return string.format(
    "ClaudeSessionLimit Status:\n启用: %s\n最大 session: %d\n检查间隔: %d秒\n计数源: herdr (本地 + %d remote)\n当前 claude agent 数: %d",
    self.enabled and "是" or "否",
    self.maxSessions,
    self.checkInterval,
    remoteCount,
    getInteractiveSessionCount()
  )
end

function obj:bindHotkeys(mapping)
  hs.spoons.bindHotkeysToSpec({
    toggle = function()
      self:toggle()
    end,
    check_now = function()
      self:checkNow()
    end,
    show_status = function()
      notifs.status(self:getStatus())
    end,
  }, mapping)
  return self
end

return obj
