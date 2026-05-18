--- === HearingToggle ===
---
--- Background sounds controller using macOS ComfortSounds assets.
--- Uses Cmd+Shift + media keys (or Cmd+Shift+F7/F8/F9 in standard-function-key mode).
---
--- Dependencies: nushell

local obj = {}
obj.__index = obj

obj.name = "HearingToggle"
obj.version = "3.0.0"
obj.author = "xbp3k"
obj.homepage = "https://github.com/xbp3k/dotfiles"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new("HearingToggle")

obj.nuPath = "/etc/profiles/per-user/luck/bin/nu"
obj.assetRoot = "/System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets"
obj.soundFile = "/tmp/bgnoise/sound"
obj.volume = "0.45"
obj.hotkeyModifiers = { "cmd", "shift" }
obj.sounds = { "rain", "stream", "ocean", "white", "pink", "brown" }
obj.soundAliases = {
  bright = "white",
  balanced = "pink",
  dark = "brown",
  water = "stream",
}

obj._eventTap = nil
obj._hotkeys = nil
obj._noiseTask = nil

-- ── helpers ──────────────────────────────────────────────────────────

local function scriptPath()
  return hs.configdir .. "/Spoons/HearingToggle.spoon/bgnoise.nu"
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function fileExists(path)
  return hs.fs.attributes(path) ~= nil
end

local function readFile(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read("*a")
  file:close()
  if not content then return nil end
  return trim(content)
end

local function writeFile(path, content)
  local file = io.open(path, "w")
  if not file then return false end
  file:write(content)
  file:close()
  return true
end

local function normalizeSound(sound)
  local raw = (sound or "rain"):lower()
  return obj.soundAliases[raw] or raw
end

local function currentSound()
  local saved = readFile(obj.soundFile)
  if not saved or saved == "" then return "rain" end
  return normalizeSound(saved)
end

local function saveCurrentSound(sound)
  writeFile(obj.soundFile, normalizeSound(sound))
end

local function soundIndex(sound)
  local normalized = normalizeSound(sound)
  for index, name in ipairs(obj.sounds) do
    if name == normalized then
      return index
    end
  end
  return 1
end

local function cycleSound(sound, delta)
  local index = soundIndex(sound)
  local nextIndex = ((index - 1 + delta) % #obj.sounds) + 1
  return obj.sounds[nextIndex]
end

local function taskEnv()
  return {
    BGNOISE_SCRIPT_PATH = scriptPath(),
    BGNOISE_VOLUME = obj.volume,
    PATH = "/etc/profiles/per-user/luck/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
  }
end

local function capture(binary, args, env)
  if not fileExists(binary) then
    return nil, "", binary .. " not found"
  end

  local exitCode, stdout, stderr
  local task = hs.task.new(binary, function(code, out, err)
    exitCode = code
    stdout = out or ""
    stderr = err or ""
  end, args or {})

  if not task then
    return nil, "", "failed to create task for " .. binary
  end

  if env then
    task:setEnvironment(env)
  end

  if not task:start() then
    return nil, "", "failed to start task for " .. binary
  end

  task:waitUntilExit()
  return exitCode, stdout or "", stderr or ""
end

local function pgMatches(pattern)
  local code, stdout = capture("/usr/bin/pgrep", { "-f", pattern })
  if code ~= 0 then return {} end

  local matches = {}
  for line in stdout:gmatch("[^\r\n]+") do
    local value = trim(line)
    if value ~= "" then
      table.insert(matches, value)
    end
  end
  return matches
end

local function modifierSetMatches(flags)
  if not flags.cmd or not flags.shift then
    return false
  end

  return not flags.ctrl and not flags.alt
end

function obj:_noiseTaskRunning()
  return self._noiseTask ~= nil and self._noiseTask:terminationReason() == false
end

function obj:_noiseRunning()
  if self:_noiseTaskRunning() then
    return true
  end

  -- We intentionally inspect the live afplay processes instead of trusting
  -- only a cached PID. The original detached-shell approach could lose track
  -- of the launcher while audio kept playing, which is why F8 looked like it
  -- "did nothing" on the second press.
  return #pgMatches(self.assetRoot) > 0
end

function obj:_cleanupNoiseProcesses()
  if self:_noiseTaskRunning() then
    self._noiseTask:terminate()
    hs.timer.usleep(150000)
  end
  self._noiseTask = nil

  -- This extra pkill is deliberate. Killing the long-lived worker alone is not
  -- enough on macOS because afplay children can outlive their parent once the
  -- process tree is torn down. If we remove this cleanup, repeated F8/F7/F9
  -- presses can leak stale Comfort Sounds players and make toggling look broken.
  capture("/usr/bin/pkill", { "-f", self.assetRoot })
  capture("/usr/bin/pkill", { "-f", scriptPath() .. " loop" })
end

function obj:_startNoise(sound)
  local normalized = normalizeSound(sound or currentSound())
  local sp = scriptPath()

  if not fileExists(self.nuPath) then
    self.logger.e("nu not found: " .. self.nuPath)
    return false
  end
  if not fileExists(sp) then
    self.logger.e("bgnoise.nu not found: " .. sp)
    return false
  end

  -- We keep the forever-running worker inside Hammerspoon instead of asking
  -- Nushell to self-background with `nohup`. That older shape was the source
  -- of the hard-to-debug behavior here: empty PID files, orphaned afplay
  -- children, and hotkeys that could no longer tell whether noise was on.
  self:_cleanupNoiseProcesses()
  saveCurrentSound(normalized)

  local task
  task = hs.task.new(self.nuPath, function(exitCode, stdout, stderr)
    if self._noiseTask == task then
      self._noiseTask = nil
    end

    local out = trim(stdout or "")
    local err = trim(stderr or "")

    if out ~= "" then
      self.logger.i(out)
    end

    if err ~= "" then
      self.logger.e(err)
    end

    -- SIGTERM from stopNoise()/toggle-off is the expected shutdown path for the
    -- managed worker. We suppress that case so the console only shows genuine
    -- failures, not every normal F8-off action.
    local reason = task and task:terminationReason() or false
    -- We suppress exit code 15 unconditionally here. In practice that is the
    -- normal shutdown path for this managed worker, but Hammerspoon's task
    -- callback does not always report the termination reason consistently at
    -- the instant the callback fires. Keeping the check at "exitCode == 15"
    -- avoids spurious warnings on ordinary F8/F7/F9 actions.
    if exitCode ~= 0 and err == "" and exitCode ~= 15 and reason ~= "interrupt" then
      self.logger.w("noise worker exited with code " .. tostring(exitCode))
    end
  end, { sp, "loop", normalized })

  task:setEnvironment(taskEnv())

  if not task:start() then
    self.logger.e("failed to start noise worker")
    return false
  end

  self._noiseTask = task
  return true
end

function obj:_statusRecord()
  return {
    noise_running = self:_noiseRunning(),
    noise_sound = currentSound(),
  }
end

function obj:_statusMessage(record)
  return string.format(
    "noise=%s (%s)",
    record.noise_running and "on" or "off",
    record.noise_sound
  )
end

function obj:_effectiveMediaFlags(event)
  local flags = event:getFlags() or {}
  if modifierSetMatches(flags) then
    return flags
  end

  -- NSSystemDefined media-key events do not always preserve the modifier flags
  -- consistently across keyboards/macOS configurations. Falling back to the
  -- live modifier state keeps Cmd+Shift+media-key handling stable whether the
  -- top row is in media-key mode or standard-function-key mode.
  return hs.eventtap.checkKeyboardModifiers() or {}
end

function obj:_handleMediaSystemKey(systemKey, flags)
  if not systemKey or not systemKey.down or systemKey["repeat"] then
    return false
  end

  if not modifierSetMatches(flags or {}) then
    return false
  end

  -- Apple keyboards and Hammerspoon do not always agree on whether the outer
  -- transport keys should be labeled NEXT/PREVIOUS or FAST/REWIND, so we accept
  -- both names to keep the behavior portable across machines.
  if systemKey.key == "PLAY" then
    self:toggle()
    return true
  end

  if systemKey.key == "NEXT" or systemKey.key == "FAST" then
    self:next()
    return true
  end

  if systemKey.key == "PREVIOUS" or systemKey.key == "REWIND" then
    self:prev()
    return true
  end

  return false
end

-- ── public methods ───────────────────────────────────────────────────

function obj:toggle()
  if self:_noiseRunning() then
    self:stopNoise()
  else
    self:_startNoise(currentSound())
  end
end

function obj:play(sound)
  self:_startNoise(sound or currentSound())
end

function obj:stopNoise()
  self:_cleanupNoiseProcesses()
end

function obj:next()
  self:_startNoise(cycleSound(currentSound(), 1))
end

function obj:prev()
  self:_startNoise(cycleSound(currentSound(), -1))
end

function obj:smartToggle()
  -- Kept as a compatibility alias for older configs/scripts. We removed the
  -- nowplaying-cli branch because the real-world playback path here is usually
  -- a browser web player, which does not reliably publish a system now-playing
  -- session on this machine. Dedicated white-noise hotkeys are less surprising.
  self:toggle()
end

function obj:smartNext()
  self:next()
end

function obj:smartPrev()
  self:prev()
end

function obj:status()
  local record = self:_statusRecord()
  hs.alert.show(self:_statusMessage(record))
  self.logger.i(hs.inspect(record))
  return record
end

-- ── lifecycle ────────────────────────────────────────────────────────

function obj:start()
  if self._hotkeys or self._eventTap then return self end

  -- Primary path: intercept Cmd+Shift + top-row media keys directly, so users
  -- do not need to hold Fn just to reach white-noise control.
  self._eventTap = hs.eventtap.new({ hs.eventtap.event.types.systemDefined }, function(event)
    local systemKey = event:systemKey()
    if not systemKey or not systemKey.key then
      return false
    end

    local handled = self:_handleMediaSystemKey(systemKey, self:_effectiveMediaFlags(event))
    return handled
  end):start()

  -- Fallback path: if the keyboard is configured to send the top row as
  -- standard function keys should still work. We keep this
  -- alongside the media-key event tap because which path fires is decided by
  -- the keyboard mode, not by Hammerspoon.
  self._hotkeys = {
    hs.hotkey.bind(self.hotkeyModifiers, "f7", function() self:prev() end),
    hs.hotkey.bind(self.hotkeyModifiers, "f8", function() self:toggle() end),
    hs.hotkey.bind(self.hotkeyModifiers, "f9", function() self:next() end),
  }

  self.logger.i("HearingToggle v3 started: Cmd+Shift+media-key white-noise controls enabled")
  return self
end

function obj:stop()
  self:stopNoise()

  if self._eventTap then
    self._eventTap:stop()
    self._eventTap = nil
  end

  if self._hotkeys then
    for _, hotkey in ipairs(self._hotkeys) do
      hotkey:delete()
    end
    self._hotkeys = nil
  end

  self.logger.i("HearingToggle stopped")
  return self
end

return obj
