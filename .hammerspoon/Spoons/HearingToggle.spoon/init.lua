--- === HearingToggle ===
---
--- Toggle macOS Background Sounds from the Hearing menu bar extra.

local obj = {}
obj.__index = obj

obj.name = "HearingToggle"
obj.version = "1.1.0"
obj.author = "OpenAI"
obj.homepage = "https://www.hammerspoon.org/"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.logger = hs.logger.new("HearingToggle")

obj.hotkey = { modifiers = { "cmd", "shift" }, key = "P" }
obj.controlCenterBundleID = "com.apple.controlcenter"
obj.hearingIdentifier = "com.apple.menuextra.hearing"
obj.hearingDescription = "Hearing"
obj.backgroundSoundsDescription = "Background Sounds"
obj.panelOpenTimeoutSeconds = 2
obj.panelPollIntervalSeconds = 0.1
obj.panelSettleSeconds = 0.15
obj.postActionSettleSeconds = 0.4

obj._toggleHotkey = nil

local sharedNotifs = dofile(hs.configdir .. "/Spoons/shared_notifs.lua")

local function notifyError(text)
  sharedNotifs.sendError("Hearing Toggle", text)
end

local function sleepSeconds(seconds)
  hs.timer.usleep(seconds * 1000000)
end

local function describeElement(element)
  if not element then
    return "nil"
  end

  return string.format(
    "role=%s desc=%s title=%s value=%s",
    tostring(element:attributeValue("AXRole")),
    tostring(element:attributeValue("AXDescription")),
    tostring(element:attributeValue("AXTitle")),
    tostring(element:attributeValue("AXValue"))
  )
end

local function findDescendant(element, predicate)
  if not element then
    return nil
  end

  if predicate(element) then
    return element
  end

  for _, child in ipairs(element:attributeValue("AXChildren") or {}) do
    local match = findDescendant(child, predicate)
    if match then
      return match
    end
  end

  return nil
end

local function getControlCenterElement()
  local app = hs.application.applicationsForBundleID(obj.controlCenterBundleID)[1]
  if not app then
    return nil, "Control Center is not running"
  end

  local element = hs.axuielement.applicationElement(app)
  if not element then
    return nil, "Unable to access Control Center accessibility element"
  end

  return element
end

local function getHearingItem(controlCenter)
  local menuBar = controlCenter:attributeValue("AXExtrasMenuBar") or controlCenter:attributeValue("AXMenuBar")
  if not menuBar then
    return nil, "Unable to access the menu bar"
  end

  for _, child in ipairs(menuBar:attributeValue("AXChildren") or {}) do
    if child:attributeValue("AXIdentifier") == obj.hearingIdentifier
      or child:attributeValue("AXDescription") == obj.hearingDescription then
      return child
    end
  end

  return nil, "Add Hearing to the menu bar first"
end

local function closePanel(hearingItem)
  if not hearingItem then
    return
  end

  for _, action in ipairs(hearingItem:actionNames() or {}) do
    if action == "AXCancel" then
      hearingItem:performAction("AXCancel")
      return
    end
  end
end

local function openPanel(controlCenter, hearingItem)
  closePanel(hearingItem)
  sleepSeconds(obj.panelSettleSeconds)
  hearingItem:performAction("AXPress")

  local attempts = math.floor(obj.panelOpenTimeoutSeconds / obj.panelPollIntervalSeconds)
  for _ = 1, attempts do
    local windows = controlCenter:attributeValue("AXWindows") or {}
    if #windows > 0 then
      return windows[1]
    end
    sleepSeconds(obj.panelPollIntervalSeconds)
  end

  return nil
end

local function inspectPanel(panelWindow)
  local offToggle = findDescendant(panelWindow, function(element)
    return element:attributeValue("AXRole") == "AXCheckBox"
      and element:attributeValue("AXDescription") == obj.backgroundSoundsDescription
      and element:attributeValue("AXValue") == 0
  end)
  if offToggle then
    return "off", offToggle, describeElement(offToggle)
  end

  local onToggle = findDescendant(panelWindow, function(element)
    return element:attributeValue("AXRole") == "AXDisclosureTriangle"
  end)
  if onToggle then
    return "on", onToggle, describeElement(onToggle)
  end

  return "unknown", nil, "No supported toggle control found"
end

local function readState(controlCenter, hearingItem)
  local panelWindow = openPanel(controlCenter, hearingItem)
  if not panelWindow then
    return nil, nil, "Unable to open the Hearing menu"
  end

  local state, control, details = inspectPanel(panelWindow)
  closePanel(hearingItem)
  sleepSeconds(obj.panelSettleSeconds)
  return state, control, details
end

local function verifyState(controlCenter, hearingItem, expectedState)
  sleepSeconds(obj.postActionSettleSeconds)
  local state, _, details = readState(controlCenter, hearingItem)
  if not state then
    return false, details
  end

  if state ~= expectedState then
    return false, string.format("Expected %s, got %s (%s)", expectedState, state, details)
  end

  return true
end

function obj:toggle()
  if not hs.accessibilityState() then
    notifyError("Grant Hammerspoon Accessibility access first")
    return false
  end

  local controlCenter, err = getControlCenterElement()
  if not controlCenter then
    notifyError(err)
    self.logger.e(err)
    return false
  end

  local hearingItem, itemErr = getHearingItem(controlCenter)
  if not hearingItem then
    notifyError(itemErr)
    self.logger.e(itemErr)
    return false
  end

  local currentState, _, details = readState(controlCenter, hearingItem)
  if not currentState then
    notifyError(details)
    self.logger.e(details)
    return false
  end

  self.logger.i("Detected state: " .. currentState .. " (" .. details .. ")")
  if currentState == "unknown" then
    local errText = "Unsupported Hearing panel layout: " .. details
    notifyError(errText)
    self.logger.e(errText)
    return false
  end

  local targetState = currentState == "off" and "on" or "off"
  local panelWindow = openPanel(controlCenter, hearingItem)
  if not panelWindow then
    local errText = "Unable to reopen the Hearing menu"
    notifyError(errText)
    self.logger.e(errText)
    return false
  end

  local actionState, actionControl, actionDetails = inspectPanel(panelWindow)
  self.logger.i("Actioning state: " .. actionState .. " (" .. actionDetails .. ")")
  if actionState ~= currentState or not actionControl then
    closePanel(hearingItem)
    local errText = string.format("State changed while opening panel: expected %s, got %s", currentState, actionState)
    notifyError(errText)
    self.logger.e(errText)
    return false
  end

  actionControl:performAction("AXPress")
  closePanel(hearingItem)

  local ok, verifyErr = verifyState(controlCenter, hearingItem, targetState)
  if not ok then
    notifyError(verifyErr)
    self.logger.e("Verification failed: " .. verifyErr)
    return false
  end

  self.logger.i("Background Sounds " .. targetState)
  return true
end

function obj:start()
  if self._toggleHotkey then
    self._toggleHotkey:delete()
  end

  self._toggleHotkey = hs.hotkey.bind(self.hotkey.modifiers, self.hotkey.key, function()
    self:toggle()
  end)

  self.logger.i("Hearing toggle hotkey registered")
  return self
end

function obj:stop()
  if self._toggleHotkey then
    self._toggleHotkey:delete()
    self._toggleHotkey = nil
  end

  self.logger.i("Hearing toggle hotkey removed")
  return self
end

return obj
