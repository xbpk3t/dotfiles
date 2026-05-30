local M = {}

local lsp_bootstrapped = false
local function configure_lsp()
  if lsp_bootstrapped then
    return
  end
  lsp_bootstrapped = true

  if not (vim.lsp and vim.lsp.config and vim.lsp.enable) then
    vim.schedule(function()
      vim.notify("vim.lsp.config/vim.lsp.enable API 不可用，已跳过自定义 LSP 启动", vim.log.levels.WARN)
    end)
    return
  end

  local ts_server = "ts_ls"
  local servers = {
    nixd = {
      settings = {
        nixd = {
          formatting = {
            command = { "nixfmt" },
          },
        },
      },
    },
    gopls = {
      settings = {
        gopls = {
          analyses = { unusedparams = true },
          staticcheck = true,
        },
      },
    },
    lua_ls = {
      settings = {
        Lua = {
          completion = { callSnippet = "Replace" },
          diagnostics = { globals = { "vim" } },
          workspace = { checkThirdParty = false },
        },
      },
    },
    clangd = {
      cmd = { "clangd", "--background-index", "--clang-tidy", "--offset-encoding=utf-8" },
    },
    pyright = {},
    html = {},
    yamlls = {
      settings = {
        yaml = {
          keyOrdering = false,
        },
      },
    },
    marksman = {},
  }

  servers[ts_server] = {
    settings = {
      javascript = { suggest = { completeFunctionCalls = true } },
      typescript = { suggest = { completeFunctionCalls = true } },
    },
  }

  for name, opts in pairs(servers) do
    local ok, err = pcall(vim.lsp.config, name, opts)
    if not ok then
      vim.notify(string.format("注册 %s LSP 失败: %s", name, err), vim.log.levels.WARN)
    end
  end

  local ok_enable, err_enable = pcall(vim.lsp.enable, vim.tbl_keys(servers))
  if not ok_enable then
    vim.notify("vim.lsp.enable 调用失败: " .. err_enable, vim.log.levels.ERROR)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    once = true,
    callback = configure_lsp,
  })
end

return M
