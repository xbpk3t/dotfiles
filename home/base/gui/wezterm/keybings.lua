return function(wezterm, config)
  config.keys = {
    { key = 'Enter',      mods = 'CTRL',  action = wezterm.action.ToggleFullScreen },
    { key = 'Enter',      mods = 'ALT',   action = wezterm.action.DisableDefaultAssignment },
    { key = 't',          mods = 'ALT',   action = wezterm.action.SpawnTab("DefaultDomain") },
    { key = 'm',          mods = 'ALT',   action = wezterm.action.ShowTabNavigator },
    { key = 'w',          mods = 'ALT',   action = wezterm.action.CloseCurrentPane { confirm = true } },
    { key = 'n',          mods = 'SUPER', action = wezterm.action.SpawnWindow },
    { key = 'd',          mods = 'ALT',   action = wezterm.action.SplitHorizontal { domain = "CurrentPaneDomain" } },
    { key = 'D',          mods = 'ALT',   action = wezterm.action.SplitVertical { domain = "CurrentPaneDomain" } },
    { key = 'h',          mods = 'ALT',   action = wezterm.action.ActivatePaneDirection("Left") },
    { key = 'j',          mods = 'ALT',   action = wezterm.action.ActivatePaneDirection("Down") },
    { key = 'k',          mods = 'ALT',   action = wezterm.action.ActivatePaneDirection("Up") },
    { key = 'l',          mods = 'ALT',   action = wezterm.action.ActivatePaneDirection("Right") },
    { key = 'LeftArrow',  mods = 'ALT',   action = wezterm.action.AdjustPaneSize { "Left", 5 } },
    { key = 'DownArrow',  mods = 'ALT',   action = wezterm.action.AdjustPaneSize { "Down", 5 } },
    { key = 'UpArrow',    mods = 'ALT',   action = wezterm.action.AdjustPaneSize { "Up", 5 } },
    { key = 'RightArrow', mods = 'ALT',   action = wezterm.action.AdjustPaneSize { "Right", 5 } },
    { key = 'L',          mods = 'ALT',   action = wezterm.action.ActivateTabRelative(1) },
    { key = 'H',          mods = 'ALT',   action = wezterm.action.ActivateTabRelative(-1) },

-- 字体大小
    { key = '+', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
    { key = '-', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
    { key = '0', mods = 'CTRL', action = wezterm.action.ResetFontSize },

    -- 复制粘贴
    { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo('Clipboard') },
    { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom('Clipboard') },
  }
end
