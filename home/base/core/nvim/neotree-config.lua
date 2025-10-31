-- Auto-refresh Neo-tree when files are created/removed
vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
  callback = function()
    local neotree = require("neo-tree")
    if neotree.is_visible() then
      neotree.refresh()
    end
  end,
})

-- Additional Neo-tree configuration
require("neo-tree").setup({
  filesystem = {
    filtered_items = {
      hide_dotfiles = false,
      hide_gitignored = false,
    },
  },
})
