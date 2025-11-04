local ok, flash = pcall(require, "flash")
if not ok then
  return
end

flash.setup({
  modes = {
    search = {
      enabled = true,
    },
    character = {
      enabled = true,
    },
  },
})

local keymap = vim.keymap.set
keymap({ "n", "x", "o" }, "s", function()
  flash.jump()
end, { desc = "Flash: jump to target" })
keymap({ "n", "x", "o" }, "S", function()
  flash.treesitter()
end, { desc = "Flash: treesitter select" })
keymap({ "o" }, "r", function()
  flash.remote()
end, { desc = "Flash: remote flash" })
keymap({ "o", "x" }, "R", function()
  flash.treesitter_search()
end, { desc = "Flash: treesitter search" })
