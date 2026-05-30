local M = {}

function M.setup()
	local function safe_telescope_builtin()
		local ok, builtin = pcall(require, "telescope.builtin")
		if not ok then
			vim.notify("Telescope 尚未就绪", vim.log.levels.ERROR)
			return nil
		end
		return builtin
	end

	_G.__nvf_open_oldfiles = function()
		local builtin = safe_telescope_builtin()
		if not builtin then
			return
		end
		builtin.oldfiles({
			cwd_only = false,
			include_current_session = true,
			only_cwd = false,
			path_display = { "truncate" },
		})
	end

	_G.__nvf_lsp_document_symbols = function()
		local builtin = safe_telescope_builtin()
		if not builtin then
			return
		end
		builtin.lsp_document_symbols({
			symbols = { "Class", "Function", "Method", "Struct", "Interface", "Module", "Field", "Variable" },
		})
	end
end

return M
