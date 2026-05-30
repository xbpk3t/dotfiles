local M = {}

function M.setup()
	local monokai = require("monokai-pro")
	monokai.setup({
		transparent_background = false,
		terminal_colors = true,
		devicons = true,
		filter = "pro",
		override = function(c)
			local bg = "#2d2a2e"
			local fg = "#fcfcfa"
			local comment = "#727072"
			local pink = "#ff6188"
			local yellow = "#ffd866"
			local green = "#a9dc76"
			local cyan = "#78dce8"
			local purple = "#ab9df2"
			local sel_bg = "#5b595c"
			return {
				["@field.yaml"] = { fg = c.base.red },
				["@property.yaml"] = { fg = c.base.red },
				["@attribute.yaml"] = { fg = c.base.red },
				Comment = { fg = comment, italic = true },
				["@comment"] = { fg = comment, italic = true },
				LineNr = { fg = "#5f5d60" },
				CursorLine = { bg = "#2f2c31" },
				CursorLineNr = { fg = "#a39fa8", bold = true },
				SignColumn = { bg = bg },
				Visual = { bg = sel_bg },
				Search = { bg = "#403e41", fg = fg },
				NormalFloat = { bg = "#2e2b30", fg = fg },
				FloatBorder = { fg = "#58565a", bg = "#2e2b30" },
				DiagnosticError = { fg = pink },
				DiagnosticWarn = { fg = yellow },
				DiagnosticInfo = { fg = cyan },
				DiagnosticHint = { fg = purple },
				DiagnosticVirtualTextError = { fg = pink, bg = "#35272d" },
				DiagnosticVirtualTextWarn = { fg = yellow, bg = "#3a3427" },
				DiagnosticVirtualTextInfo = { fg = cyan, bg = "#23343a" },
				DiagnosticVirtualTextHint = { fg = purple, bg = "#2f2b3a" },
				LspInlayHint = { fg = comment, bg = "#2f2c31", italic = false },
				MatchParen = { fg = bg, bg = "#f6a434", bold = true },
				Todo = { fg = bg, bg = yellow, bold = true },
				["@text.todo"] = { fg = bg, bg = yellow, bold = true },
				Keyword = { fg = pink, italic = true },
				Constant = { fg = purple },
				Number = { fg = purple },
				String = { fg = green },
				Function = { fg = cyan },
				Type = { fg = yellow },
				Pmenu = { bg = "#2b282d", fg = fg },
				PmenuSel = { bg = "#423f44", fg = fg, bold = true },
			}
		end,
	})
	vim.cmd([[colorscheme monokai-pro]])
end

return M
