local ok, harpoon = pcall(require, "harpoon")
if not ok then
  return
end

harpoon.setup({})

local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>ha", mark.add_file, { desc = "Harpoon: Add file" })
vim.keymap.set("n", "<leader>hh", ui.toggle_quick_menu, { desc = "Harpoon: Quick menu" })

for i = 1, 4 do
  vim.keymap.set("n", "<leader>h" .. i, function()
    ui.nav_file(i)
  end, { desc = ("Harpoon: File %d"):format(i) })
end
