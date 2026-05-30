local M = {}

function M.setup()
  local toggleterm = require("toggleterm")
  toggleterm.setup({
    start_in_insert = true,
    persist_mode = true,
    persist_size = true,
    shade_terminals = true,
    close_on_exit = false,
  })

  local function with_mouse_suppressed(bufnr, fn)
    local state = { mouse = vim.o.mouse, mousefocus = vim.o.mousefocus }
    vim.b[bufnr].__toggleterm_mouse_state = state
    vim.wo.mouse = ""
    vim.wo.mousefocus = false
    fn()
  end

  local function restore_mouse(bufnr)
    local state = vim.b[bufnr].__toggleterm_mouse_state
    if not state then
      return
    end
    vim.o.mouse = state.mouse
    vim.o.mousefocus = state.mousefocus
    vim.b[bufnr].__toggleterm_mouse_state = nil
  end

  local Terminal = require("toggleterm.terminal").Terminal
  local lazygit = Terminal:new({
    cmd = "lazygit",
    dir = "git_dir",
    direction = "float",
    hidden = true,
    close_on_exit = false,
    on_open = function(term)
      with_mouse_suppressed(term.bufnr, function()
        vim.cmd("startinsert")
      end)
    end,
    on_close = function(term)
      restore_mouse(term.bufnr)
    end,
  })

  _G.ToggleTermLazygit = function()
    lazygit:toggle()
  end

  _G.ToggleTermFocus = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "terminal" then
        vim.api.nvim_set_current_win(win)
        vim.cmd("startinsert")
        return
      end
    end
    vim.notify("没有可聚焦的终端窗口", vim.log.levels.INFO)
  end
end

return M
