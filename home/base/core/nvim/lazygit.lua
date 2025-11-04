vim.g.lazygit_floating_window_scaling_factor = 0.95
vim.g.lazygit_use_neovim_remote = 1

vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "Open LazyGit" })
vim.keymap.set("n", "<leader>gG", "<cmd>LazyGitCurrentFile<cr>", { desc = "LazyGit Current File" })
