local ok, scratch = pcall(require, "scratch")
if not ok then
  return
end

scratch.setup({
  scratch_file_dir = vim.fn.stdpath("cache") .. "/scratch.nvim",
  window_cmd = "rightbelow vsplit",
  use_telescope = true,
  file_picker = "telescope",
  -- Extend this list to add new scratch buffers for extra languages
  filetypes = { "lua", "nix", "yaml", "yml", "markdown", "md", "sh", "go" },
})

vim.keymap.set("n", "<leader>sn", "<cmd>Scratch<cr>", { desc = "Scratch: New file" })
vim.keymap.set("n", "<leader>so", "<cmd>ScratchOpen<cr>", { desc = "Scratch: Open picker" })
