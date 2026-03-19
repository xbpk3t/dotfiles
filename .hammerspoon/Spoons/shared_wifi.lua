--- === Shared WiFi Utils ===
---
--- WiFi 读取与 SSID 处理工具
--- 供多个 Spoon 复用，避免重复实现
---

local wifi = {}

-- 规范化 SSID（去掉首尾空白）
function wifi.normalizeSSID(ssid)
    if not ssid then return nil end
    local normalized = tostring(ssid):gsub("^%s+", ""):gsub("%s+$", "")
    if normalized == "" then return nil end
    return normalized
end

-- 获取 WiFi interface（优先使用显式配置）
function wifi.getWiFiInterface(preferredInterface)
    if preferredInterface and preferredInterface ~= "" then
        return preferredInterface
    end
    local interfaces = hs.wifi.interfaces() or {}
    return interfaces[1]
end

-- 获取当前 SSID（官方 API：currentNetwork + interfaceDetails）
-- Returns: ssid, interface, details
function wifi.getCurrentSSID(preferredInterface)
    local interface = wifi.getWiFiInterface(preferredInterface)
    if not interface then
        return nil, nil, {}
    end

    local ssid = wifi.normalizeSSID(hs.wifi.currentNetwork(interface))
    local details = hs.wifi.interfaceDetails(interface) or {}

    if ssid then
        return ssid, interface, details
    end

    return wifi.normalizeSSID(details.ssid), interface, details
end

-- Location Services 的英文路径提示（用于通知文案复用）
-- 因为hs必须要开启location权限，才能访问到当前wifi名
function wifi.locationServicesHint()
    return "System Settings -> Privacy & Security -> Location Services"
end

return wifi
