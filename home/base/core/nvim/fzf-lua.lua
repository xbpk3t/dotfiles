local ok, fzf = pcall(require, "fzf-lua")
if not ok then
  return
end

fzf.setup({
  winopts = {
    border = "single",
    preview = {
      layout = "vertical",
    },
  },
})

local keymap = vim.keymap.set
keymap("n", "<leader>fp", function()
  fzf.files()
end, { desc = "FZF: project files" })
keymap("n", "<leader>fg", function()
  fzf.live_grep()
end, { desc = "FZF: live grep" })
keymap("n", "<leader>fb", function()
  fzf.buffers()
end, { desc = "FZF: buffers" })
