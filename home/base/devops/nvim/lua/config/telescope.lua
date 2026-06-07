local M = {}

function M.setup()
  local telescope = require("telescope")
  telescope.setup({
    defaults = {
      file_ignore_patterns = {
        "node_modules/",
        "dist/",
        "build/",
        "target/",
      },
      vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--hidden",
      },
      dynamic_preview_title = true,
      path_display = { "truncate" },
    },
    pickers = {
      find_files = {
        hidden = true,
        follow = true,
        find_command = {
          "rg",
          "--files",
          "--hidden",
          "--follow",
          "--color=never",
        },
      },
      oldfiles = {
        cwd_only = false,
        include_current_session = true,
        only_cwd = false,
        sort_lastused = true,
      },
      live_grep = {
        additional_args = function()
          return { "--hidden" }
        end,
      },
      lsp_document_symbols = {
        symbol_width = 60,
        symbol_type_width = 12,
        symbols = { "Class", "Function", "Method", "Struct", "Interface", "Module", "Field", "Variable" },
      },
    },
  })
end

return M
