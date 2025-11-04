local ok, hurl = pcall(require, "hurl")
if not ok then
  return
end

hurl.setup({
  show_notification = false,
  mode = "split",
})

local map_opts = { noremap = true, silent = true }
vim.keymap.set("n", "<leader>Hr", "<cmd>HurlRunner<cr>", vim.tbl_extend("keep", { desc = "Hurl: run request under cursor" }, map_opts))
vim.keymap.set("n", "<leader>HA", "<cmd>HurlRunnerAll<cr>", vim.tbl_extend("keep", { desc = "Hurl: run file" }, map_opts))
vim.keymap.set("n", "<leader>HE", "<cmd>HurlSetEnv<cr>", vim.tbl_extend("keep", { desc = "Hurl: choose env file" }, map_opts))
vim.keymap.set("n", "<leader>HL", "<cmd>HurlLogs<cr>", vim.tbl_extend("keep", { desc = "Hurl: show logs" }, map_opts))
