local bleDeviceID = 'jf-airpods'

function bluetoothSwitch(state)
    -- state: 0(off), 1(on)
    cmd = "/usr/local/bin/blueutil --power " .. (state)
    print(cmd)
    result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
end

function disconnectBluetooth()
    cmd = "/usr/local/bin/blueutil --disconnect " .. (bleDeviceID)
    result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
end

function connectBluetooth()
    cmd = "/usr/local/bin/blueutil --connect " .. (bleDeviceID)
    result = hs.osascript.applescript(string.format('do shell script "%s"', cmd))
end
