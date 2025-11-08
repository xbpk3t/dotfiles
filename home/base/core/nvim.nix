{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.tui.nvf;
  scratchNvim = pkgs.vimUtils.buildVimPlugin {
    pname = "scratch.nvim";
    version = "2025-11-04";
    src = pkgs.fetchFromGitHub {
      owner = "LintaoAmons";
      repo = "scratch.nvim";
      rev = "1e78854fd3140411b231d5b6f9b3559b1ba5de77";
      sha256 = "18f6lwq6lh4qazr688hxr2qpzipdmqng24w4ikwbmgw84ngyhp9b";
    };
    dependencies = with pkgs.vimPlugins; [
      plenary-nvim
      telescope-nvim
    ];
    doCheck = false;
  };
  autoSaveLua = ''
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
        if vim.g.auto_save_respect_autocmds then
          vim.api.nvim_command("silent keepjumps noautocmd write")
        else
          vim.api.nvim_command("silent keepjumps write")
        end
      end,
    })
  '';

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
in {
  options.modules.tui.nvf = {
    enable = lib.mkEnableOption "Enable NVF (for Vim)";
  };

  config = mkIf cfg.enable {
    #    programs.neovim = {
    #      enable = true;
    #    };

    programs.nvf = {
      # 启用 nvf 程序
      enable = true;

      settings.vim = {
        # 创建 vim 和 vi 命令别名指向 nvim
        vimAlias = true;
        viAlias = true;

        # 启用 Node.js 支持（某些插件需要）
        withNodeJs = true;

        # 基础编辑器选项
        options = {
          # Tab 宽度为 2 个空格
          tabstop = 2;
          # 自动缩进宽度为 2 个空格
          shiftwidth = 2;
          # 启用绝对行号，关闭相对行号
          number = true;
          relativenumber = false;
          # 使用系统剪贴板
          clipboard = "unnamedplus";
          # 启用自动换行并在单词边界断行，保持缩进
          wrap = true;
          linebreak = true;
          breakindent = true;
          # 需要手动确认补全/代码片段，防止自动插入干扰
          completeopt = "menu,menuone,noinsert,noselect";
        };

        # 自定义快捷键映射
        keymaps = [
          # 插入模式下使用 jk 快速退出到普通模式
          {
            key = "jk";
            mode = ["i"];
            action = "<ESC>";
            desc = "Exit insert mode";
          }
          # 清除搜索高亮
          {
            key = "<leader>nh";
            mode = ["n"];
            action = ":nohl<CR>";
            desc = "Clear search highlights";
          }
          # 自动保存开关
          {
            key = "<leader>ua";
            mode = ["n"];
            action = "<cmd>AutoSaveToggle<cr>";
            desc = "Toggle global auto-save";
          }
          {
            key = "<leader>ba";
            mode = ["n"];
            action = "<cmd>AutoSaveBufferToggle<cr>";
            desc = "Toggle auto-save for buffer";
          }
          {
            key = "<leader>sa";
            mode = ["n"];
            action = "<cmd>AutoSaveAutocmdToggle<cr>";
            desc = "Toggle auto-save write autocmds";
          }
          # 使用 Telescope 按文件名搜索文件
          {
            key = "<leader>ff";
            mode = ["n"];
            action = "<cmd>Telescope find_files<cr>";
            desc = "Search files by name";
          }
          # 使用 Telescope 在文件内容中搜索（实时 grep）
          {
            key = "<leader>lg";
            mode = ["n"];
            action = "<cmd>Telescope live_grep<cr>";
            desc = "Search files by contents";
          }
          # 切换文件浏览器（Neo-tree）
          {
            key = "<leader>fe";
            mode = ["n"];
            action = "<cmd>Neotree toggle<cr>";
            desc = "File browser toggle";
          }
          # 类似 CMD+E：打开最近编辑的文件列表
          {
            key = "<leader>fr";
            mode = ["n"];
            action = "<cmd>Telescope oldfiles<cr>";
            desc = "Recent files (like CMD+E in IDEA)";
          }
          # 删除当前文件（rm + 关闭缓冲区）
          {
            key = "<leader>fd";
            mode = ["n"];
            action = "<cmd>DeleteCurrentFile<cr>";
            desc = "Delete file from disk";
          }
          {
            key = "<C-Tab>";
            mode = ["n"];
            action = "<cmd>Telescope oldfiles<cr>";
            desc = "Recent files via Ctrl+Tab";
          }
          # 插入模式下的方向键映射（Ctrl + hjkl）
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
          # 项目切换快捷键
          {
            key = "<leader>fp";
            mode = ["n"];
            action = "<cmd>Telescope projects<cr>";
            desc = "Switch between projects";
          }
          {
            key = "<leader>ft";
            mode = ["n"];
            action = "<cmd>TodoTelescope<cr>";
            desc = "Find TODO comments";
          }
          # 批量查找和替换
          {
            key = "<leader>sr";
            mode = ["n"];
            action = "<cmd>lua require('spectre').open()<cr>";
            desc = "Open Spectre for search and replace";
          }
          # 退出所有窗口并关闭 Neovim
          {
            key = "<leader>q";
            mode = ["n"];
            action = "<cmd>qa<CR>";
            desc = "Quit all buffers";
          }
          # 强制退出所有窗口（如有未保存更改）
          {
            key = "<leader>Q";
            mode = ["n"];
            action = "<cmd>qa!<CR>";
            desc = "Force quit all buffers";
          }
          # 直接删除当前行，不放入剪贴板
          {
            key = "ss";
            mode = ["n"];
            action = "\"_dd";
            desc = "Delete current line without yanking";
          }
        ];

        # 主题配置（已注释，可根据需要启用）
        # theme = {
        #   enable = true;
        #   name = "nord";
        #   style = "dark";
        #   transparent = true;
        # };

        # 启用 Telescope 模糊查找器（必需的核心插件）
        telescope.enable = true;

        # 启用拼写检查
        spellcheck = {
          enable = false;
        };

        # LSP（语言服务器协议）配置
        lsp = {
          # 启用 LSP 支持
          enable = true;
          # 只使用新的 vim.lsp.config 流程，关闭 legacy lspconfig
          # config not exist
          #"nvim-lspconfig".enable = false;
          # 保存文件时自动格式化
          formatOnSave = true;
          # LSP 图标支持
          lspkind.enable = false;
          # 代码操作提示灯泡
          lightbulb.enable = true;
          # LSP Saga UI 增强（已禁用）
          lspsaga.enable = false;
          # Trouble：更好的诊断列表
          trouble.enable = true;
          # 函数签名提示
          lspSignature.enable = true;
          # Otter：嵌入式语言支持（已禁用）
          otter-nvim.enable = false;
          # 文档查看器（已禁用）
          nvim-docs-view.enable = false;
        };

        # 编程语言支持配置
        languages = {
          # 启用代码格式化
          enableFormat = true;
          # 启用 Treesitter 语法高亮
          enableTreesitter = true;
          # 启用额外的诊断信息
          enableExtraDiagnostics = true;

          # 各语言的 LSP 支持
          nix.enable = true; # Nix 语言
          clang.enable = true; # C/C++
          # zig.enable = true; # Zig（已禁用：zig-hook 标记为损坏）
          python.enable = true; # Python
          markdown.enable = true; # Markdown
          ts.enable = true; # TypeScript/JavaScript
          html.enable = true; # HTML
          yaml.enable = true; # YAML
        };

        # 视觉增强配置
        visuals = {
          # 文件类型图标
          nvim-web-devicons.enable = true;
          # 当前行高亮
          nvim-cursorline.enable = true;
          # 平滑滚动动画
          cinnamon-nvim.enable = true;
          # LSP 进度显示
          fidget-nvim.enable = true;
          # 撤销操作高亮
          highlight-undo.enable = true;
          # 缩进参考线
          indent-blankline.enable = true;
        };

        # 自动配对括号、引号等
        autopairs.nvim-autopairs.enable = true;

        # 自动补全配置
        # [2025-11-08] 很干扰，所以设置为false
        autocomplete.nvim-cmp.enable = false;

        # 代码片段支持
        # [2025-11-07] 很干扰，所以设置为false
        snippets.luasnip.enable = false;

        # 顶部标签栏（显示打开的缓冲区）
        # [2025-11-07] 不需要
        tabline = {
          nvimBufferline.enable = false;
        };

        # Treesitter 上下文显示（显示当前函数/类名）
        treesitter.context.enable = true;

        # 快捷键绑定辅助工具
        binds = {
          # Which-Key：显示可用的快捷键提示
          whichKey.enable = true;
          # 快捷键速查表
          cheatsheet.enable = true;
        };

        # Git 集成
        git = {
          # 启用 Git 支持
          enable = true;
          # GitSigns：在行号旁显示 Git 变更标记
          gitsigns.enable = true;
          # 禁用 GitSigns 代码操作（会产生调试信息）
          gitsigns.codeActions.enable = false;
        };

        # 项目管理（支持多项目切换）
        projects.project-nvim.enable = true;

        # 启动页面（Dashboard）
        dashboard.dashboard-nvim.enable = true;

        # 文件树浏览器（Neo-tree，支持 Git 状态显示）
        filetree.neo-tree.enable = true;

        # 通知系统
        notify = {
          nvim-notify.enable = true;
          nvim-notify.setupOpts.background_colour = "#f38ba8";
        };

        # 实用工具插件
        utility = {
          # 颜色选择器（已禁用）
          ccc.enable = false;
          # WakaTime 时间追踪（已禁用）
          vim-wakatime.enable = false;
          # 图标选择器
          icon-picker.enable = true;
          # 环绕操作（快速添加/修改括号、引号等）
          surround.enable = false; # 由 extraPlugins 中的 nvim-surround 控制
          # Git diff 查看器
          diffview-nvim.enable = true;

          # 光标移动增强
          motion = {
            # Hop：快速跳转到任意位置
            hop.enable = true;
            # Leap：另一种快速跳转方式
            leap.enable = true;
            # 预知：显示可能的移动位置（已禁用）
            precognition.enable = false;
          };

          # 图像预览（已禁用）
          images = {
            image-nvim.enable = false;
          };
        };

        # UI 增强
        ui = {
          # 启用边框
          borders.enable = true;
          # Noice：更好的命令行、消息和通知 UI
          noice.enable = true;
          # 颜色代码高亮显示
          colorizer.enable = true;
          # 高亮当前光标下的相同单词
          illuminate.enable = true;

          # 面包屑导航
          breadcrumbs = {
            enable = true;
            # 代码导航器
            navbuddy.enable = true;
          };

          # 智能列标记（超过一定宽度时显示）
          smartcolumn = {
            enable = true;
          };

          # 快速操作 UI
          fastaction.enable = true;
        };

        # 会话管理（已禁用）
        session = {
          nvim-session-manager.enable = false;
        };

        # 注释插件
        comments = {
          comment-nvim.enable = true;
        };

        extraPlugins =
          (with pkgs.vimPlugins; {
            monokaiPro = {
              package = monokai-pro-nvim;
              setup = ''
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
              '';
            };

            todoComments = {
              package = todo-comments-nvim;
              setup = ''
                require("todo-comments").setup({
                  signs = true,
                  merge_keywords = true,
                  keywords = {
                    FIX = { icon = "F ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                    TODO = { icon = "T ", color = "info" },
                    HACK = { icon = "H ", color = "warning" },
                    WARN = { icon = "! ", color = "warning", alt = { "WARNING", "XXX" } },
                    PERF = { icon = "P ", color = "warning", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                    NOTE = { icon = "N ", color = "hint", alt = { "INFO" } },
                  },
                  highlight = { keyword = "bg" },
                  search = {
                    command = "rg",
                    args = {
                      "--color=never",
                      "--no-heading",
                      "--with-filename",
                      "--line-number",
                      "--column",
                    },
                    pattern = [[\b(KEYWORDS)(:|\s)]],
                  },
                })
              '';
            };

            spectre = {
              package = nvim-spectre;
              setup = ''
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

            dap = {
              package = nvim-dap;
              setup = ''
                local dap = require("dap")
                vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Continue" })
                vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
                vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
                vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
                vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
              '';
            };

            dapUi = {
              package = nvim-dap-ui;
              setup = ''
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
                vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })
              '';
            };

            harpoon = {
              package = harpoon;
              setup = ''
                local harpoon = require("harpoon")
                harpoon.setup({})
                local mark = require("harpoon.mark")
                local ui = require("harpoon.ui")
                vim.keymap.set("n", "<leader>ha", mark.add_file, { desc = "Harpoon: Add file" })
                vim.keymap.set("n", "<leader>hh", ui.toggle_quick_menu, { desc = "Harpoon: Quick menu" })
                for i = 1, 4 do
                  vim.keymap.set("n", "<leader>h" .. i, function()
                    ui.nav_file(i)
                  end, { desc = string.format("Harpoon: File %d", i) })
                end
              '';
            };

            telescopeFzf = {
              package = telescope-fzf-native-nvim;
              setup = ''
                local telescope = require("telescope")
                telescope.setup({
                  defaults = {
                    file_ignore_patterns = {
                      "%.git/",
                      "%.idea/",
                      "%.vscode/",
                      "node_modules/",
                      "dist/",
                      "build/",
                      "target/",
                    },
                  },
                  extensions = {
                    fzf = {
                      fuzzy = true,
                      override_generic_sorter = true,
                      override_file_sorter = true,
                      case_mode = "smart_case",
                    },
                  },
                })
                pcall(telescope.load_extension, "fzf")
              '';
            };

            dadbod = {
              package = vim-dadbod;
            };

            dadbodUi = {
              package = vim-dadbod-ui;
              setup = ''
                vim.g.db_ui_use_nerd_fonts = 1
                vim.g.db_ui_show_database_icon = 1
                vim.keymap.set("n", "<leader>D", "<cmd>DBUIToggle<cr>", { desc = "Toggle Database UI" })
              '';
            };

            dadbodCompletion = {
              package = vim-dadbod-completion;
            };

            plenary = {
              package = plenary-nvim;
            };

            nui = {
              package = nui-nvim;
            };

            devicons = {
              package = nvim-web-devicons;
            };

            nvimSurround = {
              package = nvim-surround;
              setup = ''
                require("nvim-surround").setup({})
              '';
            };

            flash = {
              package = flash-nvim;
              setup = ''
                local flash = require("flash")
                flash.setup({
                  modes = {
                    search = { enabled = true },
                    character = { enabled = true },
                  },
                })
                local keymap = vim.keymap.set
                keymap({ "n", "x", "o" }, "s", flash.jump, { desc = "Flash: jump to target" })
                keymap({ "n", "x", "o" }, "S", flash.treesitter, { desc = "Flash: treesitter select" })
                keymap({ "o" }, "r", flash.remote, { desc = "Flash: remote flash" })
                keymap({ "o", "x" }, "R", flash.treesitter_search, { desc = "Flash: treesitter search" })
              '';
            };

            scrollview = {
              package = nvim-scrollview;
              setup = ''
                require("scrollview").setup({ current_only = true, winblend = 25, base = "right" })
              '';
            };

            neoscroll = {
              package = neoscroll-nvim;
              setup = ''
                local neoscroll = require("neoscroll")
                neoscroll.setup({
                  hide_cursor = true,
                  stop_eof = true,
                  respect_scrolloff = false,
                  performance_mode = false,
                  easing_function = "cubic",
                  duration_multiplier = 1.15,
                  mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
                })
                local config = require("neoscroll.config")
                config.set_mappings({
                  ["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "140" } },
                  ["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "140" } },
                  ["<C-b>"] = { "scroll", { "-vim.api.nvim_win_get_height(0)", "true", "260" } },
                  ["<C-f>"] = { "scroll", { "vim.api.nvim_win_get_height(0)", "true", "260" } },
                  zt = { "zt", { "150" } },
                  zz = { "zz", { "150" } },
                  zb = { "zb", { "150" } },
                })
              '';
            };

            fzfLua = {
              package = fzf-lua;
              setup = ''
                local fzf = require("fzf-lua")
                fzf.setup({
                  winopts = { border = "single", preview = { layout = "vertical" } },
                })
                local keymap = vim.keymap.set
                keymap("n", "<leader>fp", fzf.files, { desc = "FZF: project files" })
                keymap("n", "<leader>fg", fzf.live_grep, { desc = "FZF: live grep" })
                keymap("n", "<leader>fb", fzf.buffers, { desc = "FZF: buffers" })
              '';
            };

            avante = {
              package = avante-nvim;
              setup = ''
                local ok_avante, avante = pcall(require, "avante")
                if not ok_avante then
                  return
                end

                local ok_lib, avante_lib = pcall(require, "avante_lib")
                if ok_lib and type(avante_lib) == "table" and avante_lib.load then
                  avante_lib.load()
                end

                avante.setup({
                  provider = "claude",
                  mode = "agentic",
                  auto_suggestions_provider = "claude",
                  selector = { provider = "fzf_lua" },
                  input = { provider = "native", provider_opts = {} },
                  behaviour = {
                    enable_auto_suggestions = false,
                    enable_fastapply = false,
                  },
                  suggestion = { debounce = 1500 },
                  providers = {
                    claude = {
                      endpoint = "https://api.anthropic.com",
                      model = "claude-3.5-sonnet-20241022",
                      api_key_name = "ANTHROPIC_API_KEY",
                    },
                    openai = {
                      endpoint = "https://api.openai.com/v1/chat/completions",
                      model = "gpt-4o-mini",
                      api_key_name = "OPENAI_API_KEY",
                    },
                  },
                })
              '';
            };

            lualine = {
              package = lualine-nvim;
              setup = ''
                require("lualine").setup({
                  options = {
                    theme = "auto",
                    section_separators = "",
                    component_separators = "",
                  },
                  extensions = { "quickfix" },
                })
              '';
            };

            toggleterm = {
              package = toggleterm-nvim;
              setup = ''
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
                vim.keymap.set("n", "<leader>gg", function()
                  lazygit:toggle()
                end, { desc = "Toggle Lazygit" })
                vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Toggle vertical terminal" })
                vim.keymap.set("n", "<leader>ti", function()
                  for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].buftype == "terminal" then
                      vim.api.nvim_set_current_win(win)
                      vim.cmd("startinsert")
                      return
                    end
                  end
                  vim.notify("没有可聚焦的终端窗口", vim.log.levels.INFO)
                end, { desc = "Focus terminal and start insert" })
              '';
            };

            # kulala = {
            #   package = kulala-nvim;
            #   setup = ''
            #     local kulala = require("kulala")
            #     kulala.setup({ global_keymaps = true, global_keymaps_prefix = "<leader>R" })
            #     vim.keymap.set("n", "<leader>Rr", kulala.run, { desc = "Kulala: run request" })
            #     vim.keymap.set("n", "<leader>RA", kulala.run_all, { desc = "Kulala: run all requests" })
            #     vim.keymap.set("n", "<leader>RO", kulala.open, { desc = "Kulala: open response UI" })
            #   '';
            # };

            # hurl = {
            #   package = hurl-nvim;
            #   setup = ''
            #     local hurl = require("hurl")
            #     hurl.setup({ show_notification = false, mode = "split" })
            #     local opts = { noremap = true, silent = true }
            #     vim.keymap.set("n", "<leader>Hr", "<cmd>HurlRunner<cr>", vim.tbl_extend("keep", { desc = "Hurl: run request under cursor" }, opts))
            #     vim.keymap.set("n", "<leader>HA", "<cmd>HurlRunnerAll<cr>", vim.tbl_extend("keep", { desc = "Hurl: run file" }, opts))
            #     vim.keymap.set("n", "<leader>HE", "<cmd>HurlSetEnv<cr>", vim.tbl_extend("keep", { desc = "Hurl: choose env file" }, opts))
            #     vim.keymap.set("n", "<leader>HL", "<cmd>HurlLogs<cr>", vim.tbl_extend("keep", { desc = "Hurl: show logs" }, opts))
            #   '';
            # };

            # yamlCompanion = {
            #   package = yaml-companion-nvim;
            #   setup = ''
            #     local yaml_companion = require("yaml-companion")
            #     local cfg = yaml_companion.setup({
            #       builtin_matchers = {
            #         kubernetes = { enabled = true },
            #         cloud_init = { enabled = true },
            #       },
            #     })
            #     pcall(require("telescope").load_extension, "yaml_schema")
            #     local server = "yamlls"
            #     local lsp = vim.lsp
            #     if type(lsp.config) == "table" then
            #       lsp.config[server] = vim.tbl_deep_extend("force", lsp.config[server] or {}, cfg)
            #       if type(lsp.enable) == "function" then
            #         pcall(lsp.enable, server)
            #       end
            #     end
            #   '';
            # };

            # zenMode = {
            #   package = zen-mode-nvim;
            #   setup = ''
            #     local zen = require("zen-mode")
            #     zen.setup({
            #       window = { width = 0.5, options = { number = false, relativenumber = false } },
            #       plugins = { options = { number = false, relativenumber = false } },
            #     })
            #     vim.keymap.set("n", "<leader>zz", zen.toggle, { desc = "Toggle Zen Mode" })
            #   '';
            # };
          })
          // {
            scratch = {
              package = scratchNvim;
              setup = ''
                local ok_scratch, scratch = pcall(require, "scratch")
                if not ok_scratch then
                  return
                end
                scratch.setup({
                  scratch_file_dir = vim.fn.stdpath("cache") .. "/scratch.nvim",
                  window_cmd = "rightbelow vsplit",
                  use_telescope = true,
                  file_picker = "telescope",
                  filetypes = { "lua", "nix", "yaml", "yml", "markdown", "md", "sh", "go" },
                })
                vim.keymap.set("n", "<leader>sn", "<cmd>Scratch<cr>", { desc = "Scratch: New file" })
                vim.keymap.set("n", "<leader>so", "<cmd>ScratchOpen<cr>", { desc = "Scratch: Open picker" })
              '';
            };
          };

        luaConfigRC = {
          auto-save = autoSaveLua;
          delete-current-file = deleteCurrentFileLua;
          neotree = ''
            vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
              callback = function()
                local manager_ok, manager = pcall(require, "neo-tree.sources.manager")
                if not manager_ok then
                  return
                end
                local renderer_ok, renderer = pcall(require, "neo-tree.ui.renderer")
                if not renderer_ok then
                  return
                end
                local state = manager.get_state("filesystem")
                if state and renderer.window_exists(state) then
                  manager.refresh("filesystem")
                end
              end,
            })
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
