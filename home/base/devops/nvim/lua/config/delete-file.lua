local M = {}

function M.setup()
	local function delete_current_file()
		local buf = vim.api.nvim_get_current_buf()
		local path = vim.api.nvim_buf_get_name(buf)
		if path == "" then
			vim.notify("当前缓冲区没有关联到磁盘文件", vim.log.levels.WARN)
			return
		end

		local ok_stat, stat = pcall(vim.uv.fs_stat, path)
		if not ok_stat then
			vim.notify("无法读取文件状态: " .. stat, vim.log.levels.ERROR)
			return
		end

		if stat then
			if vim.bo[buf].modified then
				vim.notify("缓冲区有未保存的修改，请先保存或放弃修改", vim.log.levels.WARN)
				return
			end

			local confirm = vim.fn.confirm(
				string.format("确认删除文件？\n\n  %s\n\n此操作不可撤销。", path),
				"&Yes\n&No",
				2
			)
			if confirm ~= 1 then
				return
			end

			local ok_delete, err = os.remove(path)
			if not ok_delete then
				vim.notify("删除失败: " .. (err or "未知错误"), vim.log.levels.ERROR)
				return
			end
		end

		vim.api.nvim_buf_delete(buf, { force = true })
		vim.notify("已删除文件: " .. path, vim.log.levels.INFO)
	end

	vim.api.nvim_create_user_command("DeleteCurrentFile", delete_current_file, {
		desc = "删除当前文件并关闭缓冲区",
	})
end

return M
