local dap = require('dap')
-- 设置断点快捷键
vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = "Debug: Continue" })
vim.keymap.set('n', '<F10>', function() dap.step_over() end, { desc = "Debug: Step Over" })
vim.keymap.set('n', '<F11>', function() dap.step_into() end, { desc = "Debug: Step Into" })
vim.keymap.set('n', '<F12>', function() dap.step_out() end, { desc = "Debug: Step Out" })
vim.keymap.set('n', '<leader>b', function() dap.toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })
