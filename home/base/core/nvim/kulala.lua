local kulala = require("kulala")

kulala.setup({
  global_keymaps = true,
  global_keymaps_prefix = "<leader>R",
})

vim.keymap.set("n", "<leader>Rr", kulala.run, { desc = "Kulala: run request" })
vim.keymap.set("n", "<leader>RA", kulala.run_all, { desc = "Kulala: run all requests" })
vim.keymap.set("n", "<leader>RO", kulala.open, { desc = "Kulala: open response UI" })
