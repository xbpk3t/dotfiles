local ok, telescope = pcall(require, "telescope")
if not ok then
  return
end

telescope.setup({
  defaults = {
    file_ignore_patterns = {
      "%.git/",
      "%.idea/",
      "%.vscode/",
      "node_modules/",
      "dist/",
      "build/",
      "target/",
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
  },
})

pcall(telescope.load_extension, "fzf")
