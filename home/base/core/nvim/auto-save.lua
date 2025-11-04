-- 自动保存：在内容变更或离开插入模式时写入文件，避免无名缓冲区等
local group = vim.api.nvim_create_augroup("AutoSaveOnChange", { clear = true })

local function should_save(buf)
  if vim.api.nvim_buf_get_option(buf, "buftype") ~= "" then
    return false
  end
  if not vim.api.nvim_buf_get_option(buf, "modifiable") then
    return false
  end
  if vim.api.nvim_buf_get_name(buf) == "" then
    return false
  end
  if vim.api.nvim_buf_get_option(buf, "readonly") then
    return false
  end
  return true
end

local function is_globally_enabled()
  if vim.g.auto_save_enabled == nil then
    vim.g.auto_save_enabled = true
  end
  return vim.g.auto_save_enabled
end

local function is_buffer_enabled(buf)
  local value = vim.b[buf].auto_save_enabled
  if value == nil then
    return true
  end
  return value
end

local function respects_autocmds()
  if vim.g.auto_save_respect_autocmds == nil then
    vim.g.auto_save_respect_autocmds = false
  end
  return vim.g.auto_save_respect_autocmds
end

local function notify_state(scope, enabled)
  local ok, notify = pcall(require, "notify")
  local message = string.format("Auto-save %s %s", scope, enabled and "enabled" or "paused")
  if ok then
    notify(message, vim.log.levels.INFO, { title = "AutoSave" })
  else
    vim.schedule(function()
      vim.notify(message, vim.log.levels.INFO)
    end)
  end
end

vim.api.nvim_create_user_command("AutoSaveToggle", function()
  local enabled = not is_globally_enabled()
  vim.g.auto_save_enabled = enabled
  notify_state("globally", enabled)
end, { desc = "Toggle global auto-save" })

vim.api.nvim_create_user_command("AutoSaveBufferToggle", function()
  local buf = vim.api.nvim_get_current_buf()
  local enabled = not is_buffer_enabled(buf)
  vim.b.auto_save_enabled = enabled
  notify_state("for buffer", enabled)
end, { desc = "Toggle auto-save for current buffer" })

vim.api.nvim_create_user_command("AutoSaveAutocmdToggle", function()
  local enabled = not respects_autocmds()
  vim.g.auto_save_respect_autocmds = enabled
  notify_state("write autocmds on auto-save", enabled)
end, { desc = "Toggle running BufWrite autocommands during auto-save" })

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave", "FocusLost" }, {
  group = group,
  callback = function(args)
    local buf = args.buf
    if not should_save(buf) or not vim.bo[buf].modified then
      return
    end
    if not (is_globally_enabled() and is_buffer_enabled(buf)) then
      return
    end

    vim.schedule(function()
      if vim.bo[buf].modified then
        local autocmd_message = respects_autocmds()
        vim.b[buf].auto_save_triggered = true
        vim.api.nvim_buf_call(buf, function()
          if autocmd_message then
            vim.cmd("silent! write")
          else
            vim.cmd("silent! noautocmd write")
          end
        end)
        vim.b[buf].auto_save_triggered = nil
      end
    end)
  end,
})
