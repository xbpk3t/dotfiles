--- === MicGuard ===
---
--- Keep the system default input on the built-in Mac microphone so Bluetooth
--- headsets stay in A2DP (music) instead of falling into HFP (call) mode.
---
--- Why this exists:
---   WeType / Zoom / FaceTime / etc. often switch default input to the headset
---   mic. For classic Bluetooth headsets that forces HFP: mono, 16 kHz, louder
---   but worse audio. Pinning input to BuiltInMicrophoneDevice avoids that
---   while still letting those apps capture voice via the Mac mic.
---
--- Design notes:
---   * Does NOT use hs.audiodevice.watcher — that API is global single-callback
---     and is already owned by AudioControl. Polling avoids stealing it.
---   * Does NOT change output devices or volume.
---   * Only acts when the current default input matches a blocked pattern
---     (Bluetooth headset mics). Other inputs are left alone.

local obj = {}
obj.__index = obj

obj.name = "MicGuard"
obj.version = "1.0.0"
obj.author = "xbp3k"
obj.homepage = "https://github.com/xbp3k/dotfiles"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new("MicGuard")

local alerts = dofile(hs.configdir .. "/Spoons/shared_alerts.lua")

--- MicGuard.preferredInputUID
--- Variable
--- CoreAudio UID of the input device to pin as default.
obj.preferredInputUID = "BuiltInMicrophoneDevice"

--- MicGuard.preferredInputNameSubstrings
--- Variable
--- Fallback name matchers if UID lookup fails (case-insensitive).
obj.preferredInputNameSubstrings = {
  "MacBook Air Microphone",
  "MacBook Pro Microphone",
  "Built%-in Microphone",
  "MacBook.*Microphone",
}

--- MicGuard.blockedInputNameSubstrings
--- Variable
--- If the current default input name matches any of these (case-insensitive),
--- MicGuard forces preferred input. Keep this focused on headset/earbud mics.
obj.blockedInputNameSubstrings = {
  "FreeBuds",
  "AirPods",
  "headphone",
  "headset",
  "earphone",
  "earbud",
  "Beats",
  "耳机",
  "耳麦",
}

--- MicGuard.blockedInputUIDSubstrings
--- Variable
--- UID fragments that mark a Bluetooth headset input (macOS uses
--- "<bt-addr>:input" for these).
obj.blockedInputUIDSubstrings = {
  ":input",
}

--- MicGuard.pollInterval
--- Variable
--- Seconds between default-input checks. 1.0 is responsive enough for WeType
--- voice sessions without measurable CPU cost.
obj.pollInterval = 1.0

--- MicGuard.alertOnFix
--- Variable
--- Show a short alert when MicGuard rewrites the default input.
obj.alertOnFix = true

--- MicGuard.alertCooldownSeconds
--- Variable
--- Minimum gap between fix alerts (avoids spam if an app keeps fighting us).
obj.alertCooldownSeconds = 30

-- internal
obj._timer = nil
obj._lastAlertAt = 0
obj._lastFixedName = nil
obj._enabled = false

local function lower(s)
  return string.lower(s or "")
end

local function nameMatchesAny(name, patterns)
  local n = lower(name)
  for _, pat in ipairs(patterns) do
    if string.find(n, lower(pat)) then
      return true
    end
  end
  return false
end

local function uidLooksBlocked(uid)
  if not uid or uid == "" then
    return false
  end
  -- Built-in / virtual UIDs we must never treat as blocked
  if uid == obj.preferredInputUID then
    return false
  end
  if string.find(uid, "BuiltIn") or string.find(uid, "CADefaultDeviceAggregate") then
    return false
  end
  for _, frag in ipairs(obj.blockedInputUIDSubstrings) do
    if string.find(uid, frag, 1, true) then
      -- Bluetooth headset inputs look like "AA-BB-CC-DD-EE-FF:input"
      if string.find(uid, "^[%x%-]+:input$") or string.find(uid, ":input$") then
        return true
      end
    end
  end
  return false
end

local function isBlockedInput(device)
  if not device then
    return false
  end
  local name = device:name() or ""
  local uid = device:uid() or ""
  if nameMatchesAny(name, obj.blockedInputNameSubstrings) then
    return true
  end
  if uidLooksBlocked(uid) and not nameMatchesAny(name, obj.preferredInputNameSubstrings) then
    return true
  end
  return false
end

local function findPreferredInput()
  local byUid = hs.audiodevice.findInputByUID(obj.preferredInputUID)
  if byUid then
    return byUid
  end
  for _, dev in ipairs(hs.audiodevice.allInputDevices()) do
    local name = dev:name() or ""
    for _, pat in ipairs(obj.preferredInputNameSubstrings) do
      if string.find(name, pat) then
        return dev
      end
    end
  end
  return nil
end

local function maybeAlert(msg)
  if not obj.alertOnFix then
    return
  end
  local now = os.time()
  if (now - obj._lastAlertAt) < obj.alertCooldownSeconds then
    return
  end
  obj._lastAlertAt = now
  alerts.info(msg, 2)
end

--- MicGuard:checkNow()
--- Method
--- Inspect default input and pin it back to the preferred device if blocked.
function obj:checkNow()
  if not self._enabled then
    return false
  end

  local current = hs.audiodevice.defaultInputDevice()
  if not current then
    return false
  end

  if not isBlockedInput(current) then
    return false
  end

  local preferred = findPreferredInput()
  if not preferred then
    self.logger.w("preferred input not found; cannot guard mic")
    return false
  end

  if current:uid() == preferred:uid() then
    return false
  end

  local fromName = current:name() or "?"
  local ok = preferred:setDefaultInputDevice()
  if ok then
    self._lastFixedName = fromName
    self.logger.i(string.format("default input %s → %s", fromName, preferred:name()))
    maybeAlert(string.format("MicGuard: 输入已切回\n%s\n(原: %s)", preferred:name(), fromName))
    return true
  end

  self.logger.w("setDefaultInputDevice failed for " .. (preferred:name() or "?"))
  return false
end

--- MicGuard:start()
function obj:start()
  if self._timer then
    return self
  end

  self._enabled = true
  self:checkNow()
  self._timer = hs.timer.doEvery(self.pollInterval, function()
    self:checkNow()
  end)
  self.logger.i(string.format("MicGuard started (poll=%.1fs, preferred=%s)", self.pollInterval, self.preferredInputUID))
  return self
end

--- MicGuard:stop()
function obj:stop()
  self._enabled = false
  if self._timer then
    self._timer:stop()
    self._timer = nil
  end
  self.logger.i("MicGuard stopped")
  return self
end

--- MicGuard:status()
function obj:status()
  local current = hs.audiodevice.defaultInputDevice()
  local preferred = findPreferredInput()
  local record = {
    enabled = self._enabled,
    polling = self._timer ~= nil,
    pollInterval = self.pollInterval,
    currentInput = current and current:name() or nil,
    currentUID = current and current:uid() or nil,
    blocked = isBlockedInput(current),
    preferredInput = preferred and preferred:name() or nil,
    preferredUID = preferred and preferred:uid() or nil,
    lastFixedFrom = self._lastFixedName,
  }
  self.logger.i(hs.inspect(record))
  alerts.info(
    string.format(
      "MicGuard %s | in=%s%s",
      record.enabled and "on" or "off",
      record.currentInput or "?",
      record.blocked and " [BLOCKED]" or ""
    ),
    3
  )
  return record
end

return obj
