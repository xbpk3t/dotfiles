-- 安装和配置用于处理 URL 的插件
-- 这个功能通常由类似 'jbyuki/carrot.nvim' 或其他 URL 处理插件提供
-- 暂时使用简单的键位映射来处理 URL
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "html" },
  callback = function()
    -- 绑定键位来打开光标下的 URL
    vim.keymap.set("n", "gx", "<cmd>lua require'nvim-web-devicons'.get_icon(vim.fn.expand('<cfile>')) ~= nil and vim.cmd('!xdg-open ' .. vim.fn.expand('<cfile>')) or vim.cmd('!xdg-open ' .. vim.fn.expand('<cWORD>'))<CR>", { silent = true, noremap = true, desc = "Open URL under cursor" })
  end,
})

-- 或者使用更简单的系统命令打开 URL
vim.keymap.set("n", "gx", [[:silent execute '!xdg-open ' . shellescape(expand('<cfile>'))<CR>]], { desc = "Open URL/file under cursor" })
