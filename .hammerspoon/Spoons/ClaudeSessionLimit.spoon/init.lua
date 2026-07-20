--- === ClaudeSessionLimit ===
---
--- 监控 Claude Code interactive 活 session 数量，超出限制时 compact alert（仅提醒）
--- 计数权威：~/.claude/sessions + kind=interactive + pid 存活
--- fallback：绝对路径 claude agents --json（避开 cmux wrapper）

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
obj.maxSessions = 12
--- 自管 timer 时的检查间隔；共享 coordinator 时由 shared_limit_alerts 驱动
obj.checkInterval = 30
--- false（默认）: 不创建周期 timer，由 init 共享节拍调用 checkNow()
obj.manageOwnTimer = false
--- Claude 活 session 登记目录
obj.sessionsDir = (os.getenv("HOME") or "") .. "/.claude/sessions"
--- fallback CLI（绝对路径，避开 PATH 上的 cmux wrapper）
obj.claudeBin = "/etc/profiles/per-user/luck/bin/claude"
--- 只计该 kind（批量 -p / daemon 等不计）
obj.kindFilter = "interactive"

obj.checkTimer = nil

local notifs = dofile(hs.configdir .. "/Spoons/ClaudeSessionLimit.spoon/notifs.lua")

local function isPidAlive(pid)
  if type(pid) ~= "number" or pid <= 0 then
    return false
  end
  local _, ok = hs.execute("/bin/kill -0 " .. pid .. " 2>/dev/null")
  return ok == true
end

--- 从 {pid, kind} 列表中统计 unique 存活 interactive
local function countInteractiveEntries(entries)
  local seen, count = {}, 0
  for _, e in ipairs(entries) do
    if e.kind == obj.kindFilter then
      local pid = tonumber(e.pid)
      if pid and not seen[pid] and isPidAlive(pid) then
        seen[pid] = true
        count = count + 1
      end
    end
  end
  return count
end

local function readSessionFile(path)
  -- io + decode；先做廉价结构预检，避免 hs.json.decode 对坏 JSON 往 console 打 LuaSkin ERROR
  local fh = io.open(path, "r")
  if not fh then
    return nil
  end
  local content = fh:read("*a")
  fh:close()
  if not content or content == "" then
    return nil
  end
  -- session 登记至少应含 "pid"；明显垃圾直接跳过
  if not content:find('"pid"', 1, true) then
    return nil
  end
  local ok, data = pcall(hs.json.decode, content)
  if ok and type(data) == "table" then
    return data
  end
  return nil
end

local function countFromSessionsDir()
  local dir = obj.sessionsDir
  if not dir or dir == "" or not hs.fs.attributes(dir, "mode") then
    obj.logger.w("sessions dir missing: " .. tostring(dir))
    return nil
  end

  local entries = {}
  for name in hs.fs.dir(dir) do
    if type(name) == "string" and name:sub(-5) == ".json" then
      local data = readSessionFile(dir .. "/" .. name)
      if data then
        entries[#entries + 1] = {
          kind = data.kind,
          pid = data.pid or name:match("^(%d+)%.json$"),
        }
      else
        obj.logger.d("skip bad session file: " .. name)
      end
    end
  end
  return countInteractiveEntries(entries)
end

local function countFromClaudeAgentsJson()
  local bin = obj.claudeBin
  if not bin or not hs.fs.attributes(bin, "mode") then
    obj.logger.w("claudeBin not found: " .. tostring(bin))
    return nil
  end

  -- 单引号包裹路径，避免空格/注入
  local output, ok = hs.execute(string.format("'%s' agents --json 2>/dev/null", bin))
  if not ok or not output or output == "" then
    obj.logger.w("claude agents --json failed")
    return nil
  end

  local decoded, data = pcall(hs.json.decode, output)
  if not decoded or type(data) ~= "table" then
    obj.logger.w("failed to parse claude agents --json")
    return nil
  end

  local entries = {}
  for _, e in ipairs(data) do
    if type(e) == "table" then
      entries[#entries + 1] = { kind = e.kind, pid = e.pid }
    end
  end
  return countInteractiveEntries(entries)
end

local function getInteractiveSessionCount()
  local count = countFromSessionsDir()
  if count ~= nil then
    obj.logger.d("count(sessions dir)=" .. count)
    return count
  end

  count = countFromClaudeAgentsJson()
  if count ~= nil then
    obj.logger.d("count(agents --json)=" .. count)
    return count
  end

  obj.logger.w("unable to count sessions; treating as 0 (no alert)")
  return 0
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

  if self.checkTimer then
    self.checkTimer:stop()
    self.checkTimer = nil
  end

  if self.manageOwnTimer then
    self.checkTimer = hs.timer.doEvery(self.checkInterval, checkSessionLimit)
    checkSessionLimit()
  end

  self.logger.i("started maxSessions=" .. self.maxSessions .. " manageOwnTimer=" .. tostring(self.manageOwnTimer))
  return self
end

function obj:stop()
  if self.checkTimer then
    self.checkTimer:stop()
    self.checkTimer = nil
  end
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
  return string.format(
    "ClaudeSessionLimit Status:\n启用: %s\n最大 session: %d\n检查间隔: %d秒\nkind 过滤: %s\n当前 interactive: %d",
    self.enabled and "是" or "否",
    self.maxSessions,
    self.checkInterval,
    tostring(self.kindFilter),
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
