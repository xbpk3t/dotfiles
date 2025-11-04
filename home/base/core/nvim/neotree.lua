-- Auto-refresh Neo-tree when files are created/removed.
vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
  callback = function()
    local manager_ok, manager = pcall(require, "neo-tree.sources.manager")
    if not manager_ok then
      return
    end

    local renderer_ok, renderer = pcall(require, "neo-tree.ui.renderer")
    if not renderer_ok then
      return
    end

    local state = manager.get_state("filesystem")
    if state and renderer.window_exists(state) then
      manager.refresh("filesystem")
    end
  end,
})

-- Additional Neo-tree configuration.
local neotree_ok, neotree = pcall(require, "neo-tree")
if not neotree_ok then
  return
end

neotree.setup({
  filesystem = {
    filtered_items = {
      hide_dotfiles = false,
      hide_gitignored = false,
    },
  },
})
