local M = {}

function M.setup()
	local function project_root()
		local buf = vim.api.nvim_get_current_buf()
		local name = vim.api.nvim_buf_get_name(buf)
		local start = (name ~= "" and vim.fs.dirname(name)) or vim.uv.cwd()
		local marker = vim.fs.find({
			".git",
			"flake.nix",
			"package.json",
			"go.mod",
			"pyproject.toml",
		}, { path = start, upward = true })[1]
		if not marker then
			return start
		end
		if marker:sub(-4) == ".git" then
			return vim.fs.dirname(marker)
		end
		return vim.fs.dirname(marker)
	end

	_G.YaziProjectRoot = function()
		local root = project_root()
		local ok, yazi = pcall(require, "yazi")
		if not ok then
			vim.notify("yazi.nvim 未安装", vim.log.levels.WARN)
			return
		end
		yazi.yazi({
			change_neovim_cwd_on_close = false,
			future_features = { use_cwd_file = false },
			hooks = {
				on_yazi_ready = function(_, config, api)
					if root then
						api:emit_to_yazi({ "cd", "--str", root })
					end
				end,
			},
		}, root)
	end
end

return M
