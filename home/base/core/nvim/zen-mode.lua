local ok, zen = pcall(require, "zen-mode")
if not ok then
  return
end

zen.setup({
  window = {
    width = 0.5,
    options = {
      number = false,
      relativenumber = false,
    },
  },
  plugins = {
    options = {
      number = false,
      relativenumber = false,
    },
  },
})

vim.keymap.set("n", "<leader>zz", function()
  zen.toggle()
end, { desc = "Toggle Zen Mode" })
