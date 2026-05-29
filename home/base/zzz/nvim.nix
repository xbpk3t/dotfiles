{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.tui.nvim;
  deleteCurrentFileLua = ''
    local function delete_current_file()
      local buf = vim.api.nvim_get_current_buf()
      local path = vim.api.nvim_buf_get_name(buf)
      if path == "" then
        vim.notify("当前缓冲区没有关联到磁盘文件", vim.log.levels.WARN)
        return
      end

      local ok_stat, stat = pcall(vim.loop.fs_stat, path)
      if not ok_stat then
        vim.notify("无法读取文件状态: " .. stat, vim.log.levels.ERROR)
        return
      end

      if stat then
        local ok_delete, err = os.remove(path)
        if not ok_delete then
          vim.notify("删除失败: " .. (err or "未知错误"), vim.log.levels.ERROR)
          return
        end
      end

      vim.api.nvim_buf_delete(buf, { force = true })
      vim.notify("已删除文件: " .. path, vim.log.levels.INFO)
    end

    vim.api.nvim_create_user_command("DeleteCurrentFile", delete_current_file, {
      desc = "删除当前文件并关闭缓冲区",
    })
  '';

  telescopeHelpersLua = ''
    local function require_telescope()
      local ok, builtin = pcall(require, "telescope.builtin")
      if not ok then
        vim.notify("Telescope 尚未就绪", vim.log.levels.ERROR)
        return nil
      end
      return builtin
    end

    function _G.__nvf_open_oldfiles()
      local builtin = require_telescope()
      if not builtin then
        return
      end
      builtin.oldfiles({
        cwd_only = false,
        include_current_session = true,
        only_cwd = false,
        path_display = { "truncate" },
      })
    end

    function _G.__nvf_lsp_document_symbols()
      local builtin = require_telescope()
      if not builtin then
        return
      end
      local clients = {}
      if vim.lsp and vim.lsp.get_clients then
        clients = vim.lsp.get_clients({ bufnr = 0 }) or {}
      end
      if vim.tbl_isempty(clients) then
        vim.notify("当前缓冲区没有附加 LSP，无法列出符号", vim.log.levels.WARN)
      end
      builtin.lsp_document_symbols({
        symbols = {
          "Class",
          "Function",
          "Method",
          "Struct",
          "Interface",
          "Module",
          "Field",
          "Variable",
        },
      })
    end
  '';

  telescopeSetupLua = ''
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
          "--no-ignore",
        },
        dynamic_preview_title = true,
        path_display = { "truncate" },
      },
      pickers = {
        find_files = {
          hidden = true,
          no_ignore = true,
          follow = true,
          find_command = {
            "rg",
            "--files",
            "--hidden",
            "--no-ignore",
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
            return { "--hidden", "--no-ignore" }
          end,
        },
        lsp_document_symbols = {
          symbol_width = 60,
          symbol_type_width = 12,
          symbols = {
            "Class",
            "Function",
            "Method",
            "Struct",
            "Interface",
            "Module",
            "Field",
            "Variable",
          },
        },
      },
    })
  '';

  lspSetupLua = ''
    local function pick_ts_server()
      for _, name in ipairs({ "ts_ls", "tsserver" }) do
        local path = package.searchpath("lspconfig.server_configurations." .. name, package.path)
        if path then
          return name
        end
      end
      return "ts_ls"
    end

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

      local ts_server = pick_ts_server()
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

    vim.api.nvim_create_autocmd("User", {
      pattern = "LazyDone",
      once = true,
      callback = configure_lsp,
    })
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = configure_lsp,
    })
  '';
in {
  options.modules.tui.nvim = {
    enable = lib.mkEnableOption "Enable NVF (for Vim)";
  };

  config = mkIf cfg.enable {
    programs.nvf = {
      enable = true;

      settings.vim = {
        vimAlias = true;
        viAlias = true;

        withNodeJs = true;

        options = {
          tabstop = 2;
          shiftwidth = 2;
          number = true;
          relativenumber = false;
          clipboard = "unnamedplus";
          wrap = true;
          linebreak = true;
          breakindent = true;
          completeopt = "menu,menuone,noinsert,noselect";
        };

        keymaps = [
          {
            key = "jk";
            mode = ["i"];
            action = "<ESC>";
            desc = "Exit insert mode";
          }
          {
            key = "<leader>nh";
            mode = ["n"];
            action = ":nohl<CR>";
            desc = "Clear search highlights";
          }
          {
            key = "<leader>ua";
            mode = ["n"];
            action = "<cmd>ASToggle<cr>";
            desc = "Toggle auto-save";
          }
          {
            key = "<leader>ff";
            mode = ["n"];
            action = "<cmd>Telescope find_files<cr>";
            desc = "Search files by name";
          }
          {
            key = "<leader>lg";
            mode = ["n"];
            action = "<cmd>Telescope live_grep<cr>";
            desc = "Search files by contents";
          }
          {
            key = "<leader>fe";
            mode = ["n"];
            action = "<cmd>lua YaziProjectRoot()<cr>";
            desc = "Project explorer (yazi)";
          }
          {
            key = "<leader>fr";
            mode = ["n"];
            action = "<cmd>lua __nvf_open_oldfiles()<cr>";
            desc = "Recent files";
          }
          {
            key = "<C-Tab>";
            mode = ["n"];
            action = "<cmd>lua __nvf_open_oldfiles()<cr>";
            desc = "Recent files via Ctrl+Tab";
          }
          {
            key = "<leader>fd";
            mode = ["n"];
            action = "<cmd>DeleteCurrentFile<cr>";
            desc = "Delete file from disk";
          }
          {
            key = "<C-h>";
            mode = ["i"];
            action = "<Left>";
            desc = "Move left in insert mode";
          }
          {
            key = "<C-j>";
            mode = ["i"];
            action = "<Down>";
            desc = "Move down in insert mode";
          }
          {
            key = "<C-k>";
            mode = ["i"];
            action = "<Up>";
            desc = "Move up in insert mode";
          }
          {
            key = "<C-l>";
            mode = ["i"];
            action = "<Right>";
            desc = "Move right in insert mode";
          }
          {
            key = "<leader>fp";
            mode = ["n"];
            action = "<cmd>Telescope projects<cr>";
            desc = "Switch between projects";
          }
          {
            key = "<leader>ls";
            mode = ["n"];
            action = "<cmd>lua __nvf_lsp_document_symbols()<cr>";
            desc = "Document symbols";
          }
          {
            key = "<leader>q";
            mode = ["n"];
            action = "<cmd>qa<CR>";
            desc = "Quit all buffers";
          }
          {
            key = "<leader>Q";
            mode = ["n"];
            action = "<cmd>qa!<CR>";
            desc = "Force quit all buffers";
          }
          {
            key = "ss";
            mode = ["n"];
            action = "\"_dd";
            desc = "Delete current line without yanking";
          }
          {
            key = "gd";
            mode = ["n"];
            action = "<cmd>lua vim.lsp.buf.definition()<cr>";
            desc = "Go to definition";
          }
          {
            key = "gD";
            mode = ["n"];
            action = "<cmd>lua vim.lsp.buf.declaration()<cr>";
            desc = "Go to declaration";
          }
          {
            key = "gI";
            mode = ["n"];
            action = "<cmd>lua vim.lsp.buf.implementation()<cr>";
            desc = "Go to implementation";
          }
          {
            key = "gr";
            mode = ["n"];
            action = "<cmd>lua vim.lsp.buf.references()<cr>";
            desc = "List references";
          }
        ];

        telescope.enable = true;

        spellcheck = {
          enable = false;
        };

        lsp = {
          enable = true;
          formatOnSave = true;
          lspkind.enable = false;
          lightbulb.enable = true;
          lspsaga.enable = false;
          trouble.enable = true;
          lspSignature.enable = true;
          otter-nvim.enable = false;
          nvim-docs-view.enable = false;
        };

        languages = {
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          nix.enable = true;
          go.enable = true;
          lua.enable = true;
          clang.enable = true;
          python.enable = true;
          markdown.enable = true;
          typescript.enable = true;
          html.enable = true;
          yaml.enable = true;
        };

        visuals = {
          nvim-web-devicons.enable = true;
          nvim-cursorline.enable = true;
          cinnamon-nvim.enable = true;
          fidget-nvim.enable = true;
          highlight-undo.enable = true;
          indent-blankline.enable = true;
        };

        autopairs.nvim-autopairs.enable = false;

        autocomplete.nvim-cmp.enable = false;

        snippets.luasnip.enable = false;

        tabline = {
          nvimBufferline.enable = false;
        };

        treesitter.context.enable = false;

        binds = {
          whichKey.enable = true;
          cheatsheet.enable = true;
        };

        git = {
          enable = true;
          gitsigns.enable = true;
          gitsigns.codeActions.enable = false;
        };

        projects.project-nvim.enable = true;

        dashboard.dashboard-nvim.enable = false;

        filetree.neo-tree.enable = false;

        notify = {
          nvim-notify.enable = true;
          nvim-notify.setupOpts.background_colour = "#f38ba8";
        };

        utility = {
          ccc.enable = false;
          vim-wakatime.enable = false;
          icon-picker.enable = true;
          surround.enable = false;
          diffview-nvim.enable = true;

          motion = {
            flash-nvim.enable = true;
            leap.enable = true;
            precognition.enable = false;
          };

          images = {
            image-nvim.enable = false;
          };
        };

        ui = {
          borders.enable = true;
          noice.enable = true;
          colorizer.enable = true;
          illuminate.enable = true;

          breadcrumbs = {
            enable = true;
            navbuddy.enable = true;
          };

          smartcolumn = {
            enable = true;
          };

          fastaction.enable = true;
        };

        session = {
          nvim-session-manager.enable = true;
        };

        comments = {
          comment-nvim.enable = true;
        };

        lazy = {
          plugins =
            (with pkgs.vimPlugins; {
              "monokai-pro.nvim" = {
                package = monokai-pro-nvim;
                lazy = false;
                priority = 1000;
                after = ''
                  local monokai = require("monokai-pro")
                  monokai.setup({
                    transparent_background = false,
                    terminal_colors = true,
                    devicons = true,
                    filter = "pro",
                    override = function(c)
                      local bg = "#2d2a2e"
                      local fg = "#fcfcfa"
                      local comment = "#727072"
                      local pink = "#ff6188"
                      local yellow = "#ffd866"
                      local green = "#a9dc76"
                      local cyan = "#78dce8"
                      local purple = "#ab9df2"
                      local sel_bg = "#5b595c"
                      return {
                        ["@field.yaml"] = { fg = c.base.red },
                        ["@property.yaml"] = { fg = c.base.red },
                        ["@attribute.yaml"] = { fg = c.base.red },
                        Comment = { fg = comment, italic = true },
                        ["@comment"] = { fg = comment, italic = true },
                        LineNr = { fg = "#5f5d60" },
                        CursorLine = { bg = "#2f2c31" },
                        CursorLineNr = { fg = "#a39fa8", bold = true },
                        SignColumn = { bg = bg },
                        Visual = { bg = sel_bg },
                        Search = { bg = "#403e41", fg = fg },
                        NormalFloat = { bg = "#2e2b30", fg = fg },
                        FloatBorder = { fg = "#58565a", bg = "#2e2b30" },
                        DiagnosticError = { fg = pink },
                        DiagnosticWarn = { fg = yellow },
                        DiagnosticInfo = { fg = cyan },
                        DiagnosticHint = { fg = purple },
                        DiagnosticVirtualTextError = { fg = pink, bg = "#35272d" },
                        DiagnosticVirtualTextWarn = { fg = yellow, bg = "#3a3427" },
                        DiagnosticVirtualTextInfo = { fg = cyan, bg = "#23343a" },
                        DiagnosticVirtualTextHint = { fg = purple, bg = "#2f2b3a" },
                        LspInlayHint = { fg = comment, bg = "#2f2c31", italic = false },
                        MatchParen = { fg = bg, bg = "#f6a434", bold = true },
                        Todo = { fg = bg, bg = yellow, bold = true },
                        ["@text.todo"] = { fg = bg, bg = yellow, bold = true },
                        Keyword = { fg = pink, italic = true },
                        Constant = { fg = purple },
                        Number = { fg = purple },
                        String = { fg = green },
                        Function = { fg = cyan },
                        Type = { fg = yellow },
                        Pmenu = { bg = "#2b282d", fg = fg },
                        PmenuSel = { bg = "#423f44", fg = fg, bold = true },
                      }
                    end,
                  })
                  vim.cmd([[colorscheme monokai-pro]])
                  vim.api.nvim_set_hl(0, "Comment", { fg = "#727072", italic = true })
                  vim.api.nvim_set_hl(0, "@comment", { fg = "#727072", italic = true })
                  vim.api.nvim_set_hl(0, "MatchParen", { fg = "#2d2a2e", bg = "#f6a434", bold = true })
                '';
              };
              "auto-save.nvim" = {
                package = auto-save-nvim;
                lazy = false;
                after = ''
                  require("auto-save").setup({})
                '';
              };

              "nvim-spectre" = {
                package = nvim-spectre;
                cmd = ["Spectre"];
                keys = [
                  {
                    key = "<leader>sr";
                    mode = ["n"];
                    action = ":lua require('spectre').open()<CR>";
                    desc = "Project replace (Spectre)";
                  }
                ];
                after = ''
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
                '';
              };

              "nvim-dap" = {
                package = nvim-dap;
                keys = [
                  {
                    key = "<F5>";
                    mode = ["n"];
                    action = ":lua require('dap').continue()<CR>";
                    desc = "Debug continue";
                  }
                  {
                    key = "<F10>";
                    mode = ["n"];
                    action = ":lua require('dap').step_over()<CR>";
                    desc = "Debug step over";
                  }
                  {
                    key = "<F11>";
                    mode = ["n"];
                    action = ":lua require('dap').step_into()<CR>";
                    desc = "Debug step into";
                  }
                  {
                    key = "<F12>";
                    mode = ["n"];
                    action = ":lua require('dap').step_out()<CR>";
                    desc = "Debug step out";
                  }
                  {
                    key = "<leader>b";
                    mode = ["n"];
                    action = ":lua require('dap').toggle_breakpoint()<CR>";
                    desc = "Toggle breakpoint";
                  }
                ];
              };

              "nvim-dap-ui" = {
                package = nvim-dap-ui;
                keys = [
                  {
                    key = "<leader>du";
                    mode = ["n"];
                    action = ":lua require('dapui').toggle()<CR>";
                    desc = "Toggle DAP UI";
                  }
                ];
                after = ''
                  local dap, dapui = require("dap"), require("dapui")
                  dapui.setup()
                  dap.listeners.after.event_initialized["dapui_config"] = function()
                    dapui.open()
                  end
                  dap.listeners.before.event_terminated["dapui_config"] = function()
                    dapui.close()
                  end
                  dap.listeners.before.event_exited["dapui_config"] = function()
                    dapui.close()
                  end
                '';
              };

              "vim-dadbod" = {
                package = vim-dadbod;
                lazy = true;
                cmd = [
                  "DB"
                  "DBUI"
                  "DBUIToggle"
                  "DBUIAddConnection"
                ];
              };

              "vim-dadbod-ui" = {
                package = vim-dadbod-ui;
                cmd = [
                  "DBUI"
                  "DBUIToggle"
                ];
                keys = [
                  {
                    key = "<leader>D";
                    mode = ["n"];
                    action = ":DBUIToggle<CR>";
                    desc = "Toggle Database UI";
                  }
                ];
                after = ''
                  vim.g.db_ui_use_nerd_fonts = 1
                  vim.g.db_ui_show_database_icon = 1
                '';
              };

              "vim-dadbod-completion" = {
                package = vim-dadbod-completion;
                lazy = true;
              };

              "plenary.nvim" = {
                package = plenary-nvim;
                lazy = true;
              };

              "nui.nvim" = {
                package = nui-nvim;
                lazy = true;
              };

              "nvim-surround" = {
                package = nvim-surround;
                event = [
                  {
                    event = "User";
                    pattern = "LazyFile";
                  }
                ];
                after = ''
                  require("nvim-surround").setup({})
                '';
              };

              "nvim-scrollview" = {
                package = nvim-scrollview;
                event = ["BufWinEnter"];
              };

              "toggleterm.nvim" = {
                package = toggleterm-nvim;
                cmd = ["ToggleTerm"];
                keys = [
                  {
                    key = "<leader>tt";
                    mode = ["n"];
                    action = ":ToggleTerm direction=vertical<CR>";
                    desc = "Vertical terminal";
                  }
                  {
                    key = "<leader>gg";
                    mode = ["n"];
                    action = ":lua ToggleTermLazygit()<CR>";
                    desc = "Toggle Lazygit";
                  }
                  {
                    key = "<leader>ti";
                    mode = ["n"];
                    action = ":lua ToggleTermFocus()<CR>";
                    desc = "Focus terminal";
                  }
                ];
                after = ''
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
                    vim.o.mouse = ""
                    vim.o.mousefocus = false
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

                  function ToggleTermLazygit()
                    lazygit:toggle()
                  end

                  function ToggleTermFocus()
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
                '';
              };

              "nvim-autopairs" = {
                package = nvim-autopairs;
                event = ["InsertEnter"];
                after = ''
                  local autopairs = require("nvim-autopairs")
                  autopairs.setup({
                    check_ts = true,
                    disable_filetype = { "TelescopePrompt" },
                    enable_check_bracket_line = false,
                    fast_wrap = {
                      map = "<M-e>",
                      chars = { "{", "[", "(", '"', "'" },
                      pattern = string.gsub([[ [%'"%)%>%]%}%,] ]], "%s+", ""),
                      end_key = "$",
                      keys = "qwertyuiopzxcvbnmasdfghjkl",
                      check_comma = true,
                      highlight = "PmenuSel",
                      highlight_grey = "Comment",
                    },
                  })

                  local ok_cmp, cmp = pcall(require, "cmp")
                  if ok_cmp then
                    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
                    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
                  end
                '';
              };
            })
            // {
              "yazi.nvim" = {
                package = pkgs.vimPlugins."yazi-nvim";
                cmd = ["Yazi"];
                keys = [
                  {
                    key = "<leader>fe";
                    mode = ["n"];
                    action = ":lua YaziProjectRoot()<CR>";
                    desc = "Explorer (yazi)";
                  }
                ];
                after = ''
                  require("yazi").setup({
                    open_for_directories = false,
                    open_multiple_tabs = false,
                    floating_window_scaling_factor = 0.92,
                    change_neovim_cwd_on_close = false,
                    highlight_hovered_buffers_in_same_directory = true,
                    future_features = { use_cwd_file = false },
                  })
                '';
              };
            };
        };

        luaConfigRC = {
          delete-current-file = deleteCurrentFileLua;
          telescope-helpers = telescopeHelpersLua;
          telescope-setup = telescopeSetupLua;
          deprecations = ''
            if vim.hl and vim.highlight ~= vim.hl then
              local priorities = vim.hl.priorities or (vim.highlight and vim.highlight.priorities)
              vim.highlight = vim.hl
              vim.highlight.priorities = priorities
            end

            if vim.lsp and vim.lsp.get_clients then
              vim.lsp.buf_get_clients = function(bufnrOrOpts)
                if type(bufnrOrOpts) == "table" then
                  return vim.lsp.get_clients(bufnrOrOpts)
                elseif type(bufnrOrOpts) == "number" then
                  return vim.lsp.get_clients({ bufnr = bufnrOrOpts })
                else
                  return vim.lsp.get_clients()
                end
              end
            end

            do
              local supports_table_spec = pcall(function()
                vim.validate({ __validate_probe = { function() end, "f" } })
              end)
              if not supports_table_spec then
                local impl = vim.validate
                vim.validate = function(spec_or_name, value, validator, optional)
                  if type(spec_or_name) == "table" and value == nil then
                    for name, spec in pairs(spec_or_name) do
                      impl(name, spec[1], spec[2], spec[3])
                    end
                    return true
                  end
                  return impl(spec_or_name, value, validator, optional)
                end
              end
            end
          '';
          lsp-setup = lspSetupLua;
          yazi-project = ''
            local function project_root()
              local buf = vim.api.nvim_get_current_buf()
              local name = vim.api.nvim_buf_get_name(buf)
              local start = (name ~= "" and vim.fs.dirname(name)) or vim.loop.cwd()
              local marker = vim.fs.find({
                ".git",
                "flake.nix",
                "package.json",
                "go.mod",
                "pyproject.toml",
              }, { path = start, upward = true })[1]
              if not marker then
                return start
              end
              if marker:sub(-4) == ".git" then
                return vim.fs.dirname(marker)
              end
              return vim.fs.dirname(marker)
            end

            function YaziProjectRoot()
              local root = project_root()
              local ok, yazi = pcall(require, "yazi")
              if not ok then
                vim.notify("yazi.nvim 未安装", vim.log.levels.WARN)
                return
              end
              yazi.yazi({
                change_neovim_cwd_on_close = false,
                future_features = { use_cwd_file = false },
                hooks = {
                  on_yazi_ready = function(_, config, api)
                    if root then
                      api:emit_to_yazi({ "cd", "--str", root })
                    end
                  end,
                },
              }, root)
            end
          '';
          treesitter = ''
            local ok_install, install = pcall(require, "nvim-treesitter.install")
            if not ok_install then
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
          '';
        };
      };
    };
  };
}
