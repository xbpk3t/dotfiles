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

local lsp_ok, lspconfig = pcall(require, "lspconfig")
if lsp_ok and lspconfig.yamlls then
  lspconfig.yamlls.setup(cfg)
end
