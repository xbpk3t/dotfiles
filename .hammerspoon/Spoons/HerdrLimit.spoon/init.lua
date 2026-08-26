--- === HerdrLimit ===
---
--- 监控 herdR 中所有未关闭（存活）agent session 数量，超出限制时 compact alert（仅提醒）
--- 计数权威：herdr 原生 `agent list`（跨 workspace，可经 --remote 覆盖远端 herdr server）
--- 计数口径：`result.agents[]` 里 `agent` 为非空字符串的条数（= 已识别为 agent 的 pane）
---   → 动态：herdr 无论后来支持多少种 agent 都自动纳入；非 agent / 裸 pane 被排除
--- 无 herdr 场景下计数为 0（不弹）

local obj = {}
obj.__index = obj

obj.name = "HerdrLimit"
obj.version = "1.1.0"
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
--- herdr CLI（绝对路径）
obj.herdrBin = "/etc/profiles/per-user/luck/bin/herdr"
--- 单次 hs.execute 超时（秒）：本地/remote 都不让它无限挂住 Hammerspoon 主线程
obj.queryTimeout = 6
--- 是否启用 remote 计数：false 时完全跳过 `--remote` 分支（连命令都不拼），不引入阻塞
obj.enableRemote = false
--- 远端 herdr server 目标列表（`herdr --remote <t> agent list`）；仅在 enableRemote=true 时生效
obj.remoteTargets = {}

local notifs = dofile(hs.configdir .. "/Spoons/HerdrLimit.spoon/notifs.lua")

--- 对单个 herdr target（nil = 本机 server）跑 `agent list`，返回已识别为 agent 的 pane 数。
--- 计数规则：`result.agents[]` 里 `agent` 为非空字符串的条数（保留 agent 字段的 pane）。
-- 返回 nil 表示该次查询失败（server 未起 / 目标不可达 / 超时），由调用方决定累计策略。
local function countAgentsFromHerdr(target)
  local cmd
  if target and target ~= "" then
    cmd = string.format("%s --remote '%s' agent list 2>/dev/null", obj.herdrBin, target)
  else
    cmd = obj.herdrBin .. " agent list 2>/dev/null"
  end

  local output, ok = hs.execute(cmd, obj.queryTimeout)
  if not ok or not output or output == "" then
    obj.logger.w("herdr agent list failed" .. (target and (" target=" .. target) or ""))
    return nil
  end

  local parseOk, data = pcall(hs.json.decode, output)
  if not parseOk or type(data) ~= "table" then
    obj.logger.w("failed to parse herdr agent list output" .. (target and (" target=" .. target) or ""))
    return nil
  end

  -- 契约：herdr 输出形状为 {"result":{"agents":[...]}}。不再回退 data.agents。
  local result = data.result
  local agents = (type(result) == "table" and result.agents) or nil
  if type(agents) ~= "table" then
    obj.logger.w("herdr agent list: no agents array")
    return nil
  end

  local count = 0
  for _, a in ipairs(agents) do
    -- 只计被 herdR 识别为 agent 的 pane：agent 字段为非空字符串。
    -- 裸 pane / 非 agent 的 terminal 会被排除。
    if type(a) == "table" and type(a.agent) == "string" and #a.agent > 0 then
      count = count + 1
    end
  end
  return count
end

--- 汇总：本地 + （仅当 enableRemote 时）各 remote target 的 agent session 数。
--- 本地查询失败视为 0；某 remote 失败记 log 但计入 0（不拖垮整体）。
--- enableRemote=false → 完全不碰 remote，天然规避多条 ssh 同步阻塞。
local function getSessionCount()
  local total = 0
  local targets = obj.remoteTargets or {}

  local count = countAgentsFromHerdr(nil)
  if count ~= nil then
    total = count
  else
    obj.logger:w("unable to count local herdr agents; treating as 0")
  end

  if obj.enableRemote then
    for _, target in ipairs(targets) do
      local rc = countAgentsFromHerdr(target)
      if rc ~= nil then
        total = total + rc
      else
        obj.logger:w("unable to count remote herdr agents target=" .. target .. "; treating as 0")
      end
    end
  end

  local remoteDesc = obj.enableRemote and ("(" .. #targets .. " remote)") or "(remote off)"
  obj.logger:d("agent session total " .. remoteDesc .. "=" .. total)
  return total
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

  self.logger:i("started maxSessions=" .. self.maxSessions .. " enableRemote=" .. tostring(self.enableRemote))
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
  local remoteInfo
  if obj.enableRemote then
    remoteInfo = "开（" .. table.concat(obj.remoteTargets or {}, ", ") .. "）"
  else
    remoteInfo = "关"
  end
  return string.format(
    "HerdrLimit Status:\n启用: %s\n最大未关闭 agent session: %d\n检查间隔: %d秒\nalertCooldown: %d秒\nremote: %s\n当前 agent session 数: %d",
    self.enabled and "是" or "否",
    self.maxSessions,
    self.checkInterval,
    self.alertCooldown,
    remoteInfo,
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
