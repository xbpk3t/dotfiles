local ok, scrollview = pcall(require, "scrollview")
if not ok then
  return
end

scrollview.setup({
  current_only = true,
  winblend = 25,
  base = "right",
})
