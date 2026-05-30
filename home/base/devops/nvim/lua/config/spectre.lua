local M = {}

function M.setup()
  require("spectre").setup({
    replace_engine = {
      ["sed"] = {
        cmd = "sed",
        args = nil,
      },
    },
    default = {
      find = { cmd = "rg", options = { "ignore-case" } },
      replace = { cmd = "sed" },
    },
  })
end

return M
