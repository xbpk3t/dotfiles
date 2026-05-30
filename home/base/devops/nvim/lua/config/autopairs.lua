local M = {}

function M.setup()
	require("nvim-autopairs").setup({
		check_ts = true,
		disable_filetype = { "TelescopePrompt" },
		enable_check_bracket_line = false,
		fast_wrap = {
			map = "<M-e>",
			chars = { "{", "[", "(", '"', "'" },
			pattern = string.gsub([[ [%'"%)%>%]%}%,] ]], "%s+", ""),
			end_key = "$",
			keys = "qwertyuiopzxcvbnmasdfghjkl",
			check_comma = true,
			highlight = "PmenuSel",
			highlight_grey = "Comment",
		},
	})
end

return M
