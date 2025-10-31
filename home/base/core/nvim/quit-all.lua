-- Quit all windows and close Neovim
vim.keymap.set('n', '<leader>q', '<cmd>qa<CR>', { desc = "Quit all buffers" })
-- Force quit all if there are unsaved changes
vim.keymap.set('n', '<leader>Q', '<cmd>qa!<CR>', { desc = "Force quit all buffers" })
