require("todo-comments").setup({
  -- 自定义 keywords，只保留您需要的
  keywords = {
    TODO = { icon = "󰓅 ", color = "info" },
    FIXME = { icon = "󰅚 ", color = "error" },
    PLAN = { icon = "󰐍 ", color = "hint" },
    MAYBE = { icon = "❓ ", color = "warning" },
  },
  merge_keywords = false, -- 只使用自定义 keywords，不合并默认 keywords
  highlight = {
    multiline = true, -- 高亮多行注释
    multiline_pattern = "^.", -- 模式匹配
    multiline_context = 10, -- 重新评估时的额外行数
    before = "", -- 高亮关键词之前的文本
    keyword = "wide", -- 高亮关键词本身，使用宽样式
    after = "fg", -- 高亮关键词之后的文本
    pattern = [[.*<(KEYWORDS)\s*:]], -- 用于高亮的模式
    comments_only = true, -- 只在注释中匹配
    max_line_len = 400, -- 忽略超过这个长度的行
    exclude = {}, -- 排除高亮的文件类型
  },
  gui_style = {
    fg = "NONE", -- 前景色的 GUI 样式
    bg = "bold", -- 背景色的 GUI 样式
  },
})
