-- Ensure nvim-treesitter parsers are written to a writable directory.
local ok, install = pcall(require, "nvim-treesitter.install")
if not ok then
  return
end

local parser_dir = vim.fs.normalize(vim.fn.stdpath("state") .. "/treesitter-parsers")
if vim.fn.isdirectory(parser_dir) == 0 then
  vim.fn.mkdir(parser_dir, "p")
end

install.parser_install_dir = parser_dir

local parser_path = vim.fs.normalize(parser_dir)
local has_path = false
for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
  if vim.fs.normalize(path) == parser_path then
    has_path = true
    break
  end
end

if not has_path then
  vim.opt.runtimepath:append(parser_path)
end
