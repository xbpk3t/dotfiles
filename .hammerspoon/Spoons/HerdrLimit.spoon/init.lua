--- === HerdrLimit ===
---
--- 监控 herdr-core 中所有未关闭（存活）agent session 数量，超出限制时 compact alert（仅提醒）
--- 计数权威：`hc ls --json` 的 terminals[]（本机 + 已连接 machine；远程地址形如 machine/t7）
--- 计数口径：state == "live" 且 status 非空（agent 已通过 OSC 报告状态）的条数；
---   裸 shell / 未报告状态的普通程序不计入。
--- 无 hc / core 未运行时计数为 0（不弹）

local obj = {}
obj.__index = obj

obj.name = "HerdrLimit"
obj.version = "2.0.0"
obj.author = "luck"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new("HerdrLimit")

--- 是否启用
obj.enabled = true
--- 最大未关闭 agent session 数
obj.maxSessions = 25
--- 检查间隔（秒）；status 展示用，实际节拍由 init 共享 coordinator 驱动
obj.checkInterval = 30
--- 告警冷却（秒）：同一持续超限状态不重复弹，避免每 30s 刷屏
obj.alertCooldown = 60
--- hc CLI（herdr-core）；默认自动探测，可在 config 里覆盖
local function resolveHcBin()
  local user = os.getenv("USER") or "luck"
  local home = os.getenv("HOME") or ""
  local candidates = {
    "/etc/profiles/per-user/" .. user .. "/bin/hc",
    "/opt/homebrew/bin/hc",
    "/usr/local/bin/hc",
    home .. "/.local/bin/hc",
  }
  for _, p in ipairs(candidates) do
    local f = io.open(p, "r")
    if f then
      f:close()
      return p
    end
  end
  local out = hs.execute("command -v hc 2>/dev/null")
  if out and out ~= "" then
    return out:gsub("%s+$", "")
  end
  return "hc"
end

obj.hcBin = resolveHcBin()
--- 单次 hs.execute 超时（秒）：hc ls 会汇总远程 machine，给它一点余量
obj.queryTimeout = 8

local notifs = dofile(hs.configdir .. "/Spoons/HerdrLimit.spoon/notifs.lua")

--- 跑 `hc ls --json`，返回已报告状态的 live agent session 数。
--- hc 的 terminals[] 同时包含本机与已连接 machine 的终端（machine/t7）；
--- machine 未连接时不会出现在结果里，也不会阻塞。
-- 返回 nil 表示查询失败（hc 未安装 / core 未起 / 超时），由调用方按 0 处理。
local function countAgentsFromHc()
  local cmd = obj.hcBin .. " ls --json 2>/dev/null"
  local output, ok = hs.execute(cmd, obj.queryTimeout)
  if not ok or not output or output == "" then
    obj.logger:w("hc ls failed")
    return nil
  end

  local parseOk, data = pcall(hs.json.decode, output)
  if not parseOk or type(data) ~= "table" then
    obj.logger:w("failed to parse hc ls output")
    return nil
  end

  local terminals = data.terminals
  if type(terminals) ~= "table" then
    obj.logger:w("hc ls: no terminals array")
    return nil
  end

  local count = 0
  for _, t in ipairs(terminals) do
    -- 只计 live 且已报告 agent 状态的 terminal；裸 shell / 普通程序没有 status。
    -- reported 是兜底：某些 agent 可能先上报过、当前 status 暂空。
    if type(t) == "table" and t.state == "live" and (t.status ~= nil or t.reported == true) then
      count = count + 1
    end
  end
  return count
end

--- 汇总当前 agent session 数；查询失败视为 0，不拖垮整体。
local function getSessionCount()
  local count = countAgentsFromHc()
  if count == nil then
    obj.logger:w("unable to count hc agents; treating as 0")
    return 0
  end
  obj.logger:d("agent session total=" .. count)
  return count
end

-- 上次告警时间（cooldown 去重用）
local lastAlertAt = 0

local function checkSessionLimit()
  if not obj.enabled then
    return
  end

  local n = getSessionCount()
  if n > obj.maxSessions then
    local now = os.time()
    if now - lastAlertAt >= obj.alertCooldown then
      lastAlertAt = now
      local excess = n - obj.maxSessions
      notifs.sessionLimitExceeded(n, obj.maxSessions, excess)
      obj.logger:w(string.format("limit exceeded: current=%d max=%d excess=%d", n, obj.maxSessions, excess))
    else
      obj.logger:d("still over limit, alert suppressed by cooldown current=" .. n)
    end
  end
end

--- 立即检查（共享 coordinator / 热键）
function obj:checkNow()
  checkSessionLimit()
  return self
end

function obj:start()
  if not self.enabled then
    self.logger:i("disabled, not starting")
    return self
  end

  self.logger:i("started maxSessions=" .. self.maxSessions)
  return self
end

function obj:stop()
  self.logger:i("stopped")
  return self
end

function obj:toggle()
  if self.enabled then
    self:stop()
    self.enabled = false
    notifs.disabled()
    self.logger:i("disabled")
  else
    self.enabled = true
    self:start()
    notifs.enabled()
    self.logger:i("enabled")
  end
  return self
end

--- 供 console / 测试：返回当前未关闭 agent session 数
function obj:getCount()
  return getSessionCount()
end

function obj:getStatus()
  return string.format(
    "HerdrLimit Status:\n启用: %s\n最大未关闭 agent session: %d\n检查间隔: %d秒\nalertCooldown: %d秒\n计数: hc ls --json（本机 + 已连接 machine）\n当前 agent session 数: %d",
    self.enabled and "是" or "否",
    self.maxSessions,
    self.checkInterval,
    self.alertCooldown,
    getSessionCount()
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
