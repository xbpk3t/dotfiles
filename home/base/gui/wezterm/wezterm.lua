local wezterm = require("wezterm")

local config = wezterm.config_builder()

require("appearance")(wezterm, config)
require("keybings")(wezterm, config)
require("status")(wezterm, config)
require("tabs")(wezterm, config)

return config