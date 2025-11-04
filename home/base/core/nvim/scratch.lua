local ok, scratch = pcall(require, "scratch")
if not ok then
  return
end

scratch.setup({
  scratch_file_dir = vim.fn.stdpath("cache") .. "/scratch.nvim",
  window_cmd = "rightbelow vsplit",
  use_telescope = true,
  file_picker = "telescope",
  filetypes = { "lua", "nix", "yaml", "markdown", "sh" },
})

vim.keymap.set("n", "<leader>sn", "<cmd>Scratch<cr>", { desc = "Scratch: New file" })
vim.keymap.set("n", "<leader>so", "<cmd>ScratchOpen<cr>", { desc = "Scratch: Open picker" })
