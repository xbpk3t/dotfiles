local ok, lualine = pcall(require, "lualine")
if not ok then
  return
end

lualine.setup({
  options = {
    theme = "auto",
    section_separators = "",
    component_separators = "",
  },
  extensions = { "quickfix" },
})
