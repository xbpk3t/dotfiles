-- Theme configuration for NVF/Neovim.
-- Default to Monokai Pro to match the inline configuration in luaConfigRC.
-- local monokai_ok, monokai = pcall(require, "monokai-pro")
-- if monokai_ok then
--   monokai.setup({
--     transparent_background = false,
--     terminal_colors = true,
--     devicons = true,
--     filter = "pro", -- classic | octagon | pro | machine | ristretto | spectrum
--     override = function(c)
--       return {
--         ["@field.yaml"] = { fg = c.base.red },
--         ["@property.yaml"] = { fg = c.base.red },
--         ["@attribute.yaml"] = { fg = c.base.red },
--       }
--     end,
--   })
--   vim.cmd([[colorscheme monokai-pro]])
-- end









local monokai_ok, monokai = pcall(require, "monokai-pro")
if monokai_ok then
  monokai.setup({
    transparent_background = false,
    terminal_colors = true,
    devicons = true,
    filter = "pro", -- pro | classic | octagon | machine | ristretto | spectrum
    override = function(c)
      -- 官方 / 常见移植中的核心色
      local bg        = "#2d2a2e"
      local fg        = "#fcfcfa"
      local comment   = "#727072"
      local pink      = "#ff6188" -- error / keywords 等
      local orange    = "#fc9867"
      local yellow    = "#ffd866"
      local green     = "#a9dc76"
      local cyan      = "#78dce8"
      local purple    = "#ab9df2"
      local sel_bg    = "#5b595c" -- 选区

      return {
        -- 你原来的 YAML 调整
        ["@field.yaml"]     = { fg = c.base.red },
        ["@property.yaml"]  = { fg = c.base.red },
        ["@attribute.yaml"] = { fg = c.base.red },

        -- 注释（Treesitter + 传统 hl 组）
        Comment     = { fg = comment, italic = true },
        ["@comment"] = { fg = comment, italic = true },

        -- 行号/边栏，贴近 JetBrains 的“隐身感”
        LineNr      = { fg = "#5f5d60" },
        CursorLine  = { bg = "#2f2c31" },
        CursorLineNr= { fg = "#a39fa8", bold = true },
        SignColumn  = { bg = bg },

        -- 选区/匹配
        Visual      = { bg = sel_bg },
        Search      = { bg = "#403e41", fg = fg },

        -- 浮窗/边框
        NormalFloat = { bg = "#2e2b30", fg = fg },
        FloatBorder = { fg = "#58565a", bg = "#2e2b30" },

        -- LSP 诊断（颜色更贴近 IDEA）
        DiagnosticError = { fg = pink },
        DiagnosticWarn  = { fg = yellow },
        DiagnosticInfo  = { fg = cyan },
        DiagnosticHint  = { fg = purple },

        DiagnosticVirtualTextError = { fg = pink,   bg = "#35272d" },
        DiagnosticVirtualTextWarn  = { fg = yellow, bg = "#3a3427" },
        DiagnosticVirtualTextInfo  = { fg = cyan,   bg = "#23343a" },
        DiagnosticVirtualTextHint  = { fg = purple, bg = "#2f2b3a" },

        -- Inlay Hints（参数提示）——更像 JetBrains
        LspInlayHint = { fg = comment, bg = "#2f2c31", italic = false },

        -- Todo/Fixme 等标签在 Monokai 家族里通常更显眼
        Todo        = { fg = bg, bg = yellow, bold = true },
        ["@text.todo"] = { fg = bg, bg = yellow, bold = true },

        -- 关键字/常量等稍作对齐（如果你觉得默认不够“IDEA 味”）
        Keyword     = { fg = pink, italic = true },
        Constant    = { fg = purple },
        Number      = { fg = purple },
        String      = { fg = green },
        Function    = { fg = cyan },
        Type        = { fg = yellow },

        -- 弹窗菜单/选项
        Pmenu       = { bg = "#2b282d", fg = fg },
        PmenuSel    = { bg = "#423f44", fg = fg, bold = true },
      }
    end,
  })
  vim.cmd([[colorscheme monokai-pro]])

  -- （可选）再保险：主题加载后再覆写一次注释，防止其他插件改色
  vim.api.nvim_set_hl(0, "Comment", { fg = "#727072", italic = true })
  vim.api.nvim_set_hl(0, "@comment", { fg = "#727072", italic = true })
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
