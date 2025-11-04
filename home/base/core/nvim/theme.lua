-- Theme configuration for NVF/Neovim.
-- Default to Monokai Pro to match the inline configuration in luaConfigRC.
local monokai_ok, monokai = pcall(require, "monokai-pro")
if monokai_ok then
  monokai.setup({
    transparent_background = false,
    terminal_colors = true,
    devicons = true,
    filter = "pro", -- classic | octagon | pro | machine | ristretto | spectrum
  })
  vim.cmd([[colorscheme monokai-pro]])
end

-- Alternative theme example (TokyoNight). Uncomment if you prefer it.
-- local tokyonight_ok, tokyonight = pcall(require, "tokyonight")
-- if tokyonight_ok then
--   tokyonight.setup({
--     style = "storm",
--     light_style = "day",
--     transparent = false,
--     terminal_colors = true,
--     styles = {
--       comments = { italic = true },
--       keywords = { italic = true },
--       functions = {},
--       variables = {},
--       sidebars = "dark",
--       floats = "dark",
--     },
--     sidebars = { "qf", "help" },
--     day_brightness = 0.3,
--     hide_inactive_statusline = false,
--     dim_inactive = false,
--     lualine_bold = false,
--   })
--   vim.cmd([[colorscheme tokyonight]])
-- end
