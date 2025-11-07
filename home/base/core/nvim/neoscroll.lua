local ok, neoscroll = pcall(require, "neoscroll")
if not ok then
  return
end

neoscroll.setup({
  hide_cursor = true,
  stop_eof = true,
  respect_scrolloff = true,
  performance_mode = true,
  easing_function = "quadratic",
  -- 使用setup中的mappings配置，而不是单独调用set_mappings
  mappings = {
    "<C-u>",
    "<C-d>",
    "<C-b>",
    "<C-f>",
    "<C-y>",
    "<C-e>",
    "zt",
    "zz",
    "zb",
  },
})

-- 如果需要自定义滚动速度，可以通过配置参数来实现，而不是使用set_mappings
