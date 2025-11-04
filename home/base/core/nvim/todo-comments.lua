local todo_ok, todo = pcall(require, "todo-comments")
if not todo_ok then
  return
end

todo.setup({
  signs = true,
  merge_keywords = true,
  keywords = {
    FIX = { icon = "F ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
    TODO = { icon = "T ", color = "info" },
    HACK = { icon = "H ", color = "warning" },
    WARN = { icon = "! ", color = "warning", alt = { "WARNING", "XXX" } },
    PERF = { icon = "P ", color = "warning", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
    NOTE = { icon = "N ", color = "hint", alt = { "INFO" } },
  },
  highlight = {
    keyword = "bg",
  },
  search = {
    command = "rg",
    args = {
      "--color=never",
      "--no-heading",
      "--with-filename",
      "--line-number",
      "--column",
    },
    -- Allow either `FIXME` or `FIXME:` style
    pattern = [[\b(KEYWORDS)(:|\s)]],
  },
})
