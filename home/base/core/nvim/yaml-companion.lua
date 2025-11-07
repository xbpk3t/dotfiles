local ok, yaml_companion = pcall(require, "yaml-companion")
if not ok then
  return
end

local cfg = yaml_companion.setup({
  builtin_matchers = {
    kubernetes = { enabled = true },
    cloud_init = { enabled = true },
  },
})

pcall(require("telescope").load_extension, "yaml_schema")

if type(cfg) ~= "table" then
  return
end

local lsp = vim.lsp
if not lsp or type(lsp.config) ~= "table" then
  return
end

local server = "yamlls"
local merged = vim.tbl_deep_extend("force", lsp.config[server] or {}, cfg)
lsp.config[server] = merged

if type(lsp.enable) == "function" then
  local ok_enable, err = pcall(lsp.enable, server)
  if not ok_enable then
    vim.schedule(function()
      vim.notify(string.format("Failed to enable %s: %s", server, err), vim.log.levels.WARN)
    end)
  end
end
