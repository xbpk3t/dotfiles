-- 启用 unnamedplus 选项，使默认的复制粘贴使用系统剪贴板
vim.o.clipboard = "unnamedplus"


-- Quit all windows and close Neovim
vim.keymap.set('n', '<leader>q', '<cmd>qa<CR>', { desc = "Quit all buffers" })
-- Force quit all if there are unsaved changes
vim.keymap.set('n', '<leader>Q', '<cmd>qa!<CR>', { desc = "Force quit all buffers" })

-- 自定义映射：ss 直接删除当前行，不放入剪贴板
vim.keymap.set('n', 'ss', '"_dd', { desc = "Delete current line without yanking" })



-- 启用绝对行号
vim.o.number = true
-- 禁用相对行号
vim.o.relativenumber = false
