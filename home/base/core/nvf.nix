# NVF (Neovim from Flake) 配置文件
# NVF 是一个基于 Nix 的模块化 Neovim 配置框架
{...}: {
  # programs.nvf = {
  #   # 启用 nvf 程序
  #   enable = true;

  #   settings.vim = {
  #     # 创建 vim 和 vi 命令别名指向 nvim
  #     vimAlias = true;
  #     viAlias = true;

  #     # 启用 Node.js 支持（某些插件需要）
  #     withNodeJs = true;

  #     # 基础编辑器选项
  #     options = {
  #       # Tab 宽度为 2 个空格
  #       tabstop = 2;
  #       # 自动缩进宽度为 2 个空格
  #       shiftwidth = 2;
  #       # 禁用自动换行
  #       wrap = false;
  #     };

  #     # 自定义快捷键映射
  #     keymaps = [
  #       # 插入模式下使用 jk 快速退出到普通模式
  #       {
  #         key = "jk";
  #         mode = ["i"];
  #         action = "<ESC>";
  #         desc = "Exit insert mode";
  #       }
  #       # 清除搜索高亮
  #       {
  #         key = "<leader>nh";
  #         mode = ["n"];
  #         action = ":nohl<CR>";
  #         desc = "Clear search highlights";
  #       }
  #       # 使用 Telescope 按文件名搜索文件
  #       {
  #         key = "<leader>ff";
  #         mode = ["n"];
  #         action = "<cmd>Telescope find_files<cr>";
  #         desc = "Search files by name";
  #       }
  #       # 使用 Telescope 在文件内容中搜索（实时 grep）
  #       {
  #         key = "<leader>lg";
  #         mode = ["n"];
  #         action = "<cmd>Telescope live_grep<cr>";
  #         desc = "Search files by contents";
  #       }
  #       # 切换文件浏览器（Neo-tree）
  #       {
  #         key = "<leader>fe";
  #         mode = ["n"];
  #         action = "<cmd>Neotree toggle<cr>";
  #         desc = "File browser toggle";
  #       }
  #       # 类似 CMD+E：打开最近编辑的文件列表
  #       {
  #         key = "<leader>fr";
  #         mode = ["n"];
  #         action = "<cmd>Telescope oldfiles<cr>";
  #         desc = "Recent files (like CMD+E in IDEA)";
  #       }
  #       # 插入模式下的方向键映射（Ctrl + hjkl）
  #       {
  #         key = "<C-h>";
  #         mode = ["i"];
  #         action = "<Left>";
  #         desc = "Move left in insert mode";
  #       }
  #       {
  #         key = "<C-j>";
  #         mode = ["i"];
  #         action = "<Down>";
  #         desc = "Move down in insert mode";
  #       }
  #       {
  #         key = "<C-k>";
  #         mode = ["i"];
  #         action = "<Up>";
  #         desc = "Move up in insert mode";
  #       }
  #       {
  #         key = "<C-l>";
  #         mode = ["i"];
  #         action = "<Right>";
  #         desc = "Move right in insert mode";
  #       }
  #       # 项目切换快捷键
  #       {
  #         key = "<leader>fp";
  #         mode = ["n"];
  #         action = "<cmd>Telescope projects<cr>";
  #         desc = "Switch between projects";
  #       }
  #       # TODO 注释快速跳转
  #       {
  #         key = "<leader>ft";
  #         mode = ["n"];
  #         action = "<cmd>TodoTelescope<cr>";
  #         desc = "Find TODO comments";
  #       }
  #       # 批量查找和替换
  #       {
  #         key = "<leader>sr";
  #         mode = ["n"];
  #         action = "<cmd>lua require('spectre').open()<cr>";
  #         desc = "Open Spectre for search and replace";
  #       }
  #     ];

  #     # 主题配置（已注释，可根据需要启用）
  #     # theme = {
  #     #   enable = true;
  #     #   name = "nord";
  #     #   style = "dark";
  #     #   transparent = true;
  #     # };

  #     # 启用 Telescope 模糊查找器（必需的核心插件）
  #     telescope.enable = true;

  #     # 启用拼写检查
  #     spellcheck = {
  #       enable = true;
  #     };

  #     # LSP（语言服务器协议）配置
  #     lsp = {
  #       # 启用 LSP 支持
  #       enable = true;
  #       # 保存文件时自动格式化
  #       formatOnSave = true;
  #       # LSP 图标支持
  #       lspkind.enable = false;
  #       # 代码操作提示灯泡
  #       lightbulb.enable = true;
  #       # LSP Saga UI 增强（已禁用）
  #       lspsaga.enable = false;
  #       # Trouble：更好的诊断列表
  #       trouble.enable = true;
  #       # 函数签名提示
  #       lspSignature.enable = true;
  #       # Otter：嵌入式语言支持（已禁用）
  #       otter-nvim.enable = false;
  #       # 文档查看器（已禁用）
  #       nvim-docs-view.enable = false;
  #     };

  #     # 编程语言支持配置
  #     languages = {
  #       # 启用代码格式化
  #       enableFormat = true;
  #       # 启用 Treesitter 语法高亮
  #       enableTreesitter = true;
  #       # 启用额外的诊断信息
  #       enableExtraDiagnostics = true;

  #       # 各语言的 LSP 支持
  #       nix.enable = true; # Nix 语言
  #       clang.enable = true; # C/C++
  #       # zig.enable = true; # Zig（已禁用：zig-hook 标记为损坏）
  #       python.enable = true; # Python
  #       markdown.enable = true; # Markdown
  #       ts.enable = true; # TypeScript/JavaScript
  #       html.enable = true; # HTML
  #     };

  #     # 视觉增强配置
  #     visuals = {
  #       # 文件类型图标
  #       nvim-web-devicons.enable = true;
  #       # 当前行高亮
  #       nvim-cursorline.enable = true;
  #       # 平滑滚动动画
  #       cinnamon-nvim.enable = true;
  #       # LSP 进度显示
  #       fidget-nvim.enable = true;
  #       # 撤销操作高亮
  #       highlight-undo.enable = true;
  #       # 缩进参考线
  #       indent-blankline.enable = true;
  #     };

  #     # 自动配对括号、引号等
  #     autopairs.nvim-autopairs.enable = true;

  #     # 自动补全配置
  #     autocomplete.nvim-cmp.enable = true;
  #     # 代码片段支持
  #     snippets.luasnip.enable = true;

  #     # 顶部标签栏（显示打开的缓冲区）
  #     tabline = {
  #       nvimBufferline.enable = true;
  #     };

  #     # Treesitter 上下文显示（显示当前函数/类名）
  #     treesitter.context.enable = true;

  #     # 快捷键绑定辅助工具
  #     binds = {
  #       # Which-Key：显示可用的快捷键提示
  #       whichKey.enable = true;
  #       # 快捷键速查表
  #       cheatsheet.enable = true;
  #     };

  #     # Git 集成
  #     git = {
  #       # 启用 Git 支持
  #       enable = true;
  #       # GitSigns：在行号旁显示 Git 变更标记
  #       gitsigns.enable = true;
  #       # 禁用 GitSigns 代码操作（会产生调试信息）
  #       gitsigns.codeActions.enable = false;
  #     };

  #     # 项目管理（支持多项目切换）
  #     projects.project-nvim.enable = true;

  #     # 启动页面（Dashboard）
  #     dashboard.dashboard-nvim.enable = true;

  #     # 文件树浏览器（Neo-tree，支持 Git 状态显示）
  #     filetree.neo-tree.enable = true;

  #     # 通知系统
  #     notify = {
  #       nvim-notify.enable = true;
  #       nvim-notify.setupOpts.background_colour = "#f38ba8";
  #     };

  #     # 实用工具插件
  #     utility = {
  #       # 颜色选择器（已禁用）
  #       ccc.enable = false;
  #       # WakaTime 时间追踪（已禁用）
  #       vim-wakatime.enable = false;
  #       # 图标选择器
  #       icon-picker.enable = true;
  #       # 环绕操作（快速添加/修改括号、引号等）
  #       surround.enable = true;
  #       # Git diff 查看器
  #       diffview-nvim.enable = true;

  #       # 光标移动增强
  #       motion = {
  #         # Hop：快速跳转到任意位置
  #         hop.enable = true;
  #         # Leap：另一种快速跳转方式
  #         leap.enable = true;
  #         # 预知：显示可能的移动位置（已禁用）
  #         precognition.enable = false;
  #       };

  #       # 图像预览（已禁用）
  #       images = {
  #         image-nvim.enable = false;
  #       };
  #     };

  #     # UI 增强
  #     ui = {
  #       # 启用边框
  #       borders.enable = true;
  #       # Noice：更好的命令行、消息和通知 UI
  #       noice.enable = true;
  #       # 颜色代码高亮显示
  #       colorizer.enable = true;
  #       # 高亮当前光标下的相同单词
  #       illuminate.enable = true;

  #       # 面包屑导航
  #       breadcrumbs = {
  #         enable = true;
  #         # 代码导航器
  #         navbuddy.enable = true;
  #       };

  #       # 智能列标记（超过一定宽度时显示）
  #       smartcolumn = {
  #         enable = true;
  #       };

  #       # 快速操作 UI
  #       fastaction.enable = true;
  #     };

  #     # 会话管理（已禁用）
  #     session = {
  #       nvim-session-manager.enable = false;
  #     };

  #     # 注释插件
  #     comments = {
  #       comment-nvim.enable = true;
  #     };

  #     # 自定义插件列表
  #     # 使用 vim.startPlugins 添加 nvf 未内置的插件
  #     startPlugins = with pkgs.vimPlugins; [
  #       # 2. Monokai Pro 主题（类似 IDEA 的 Monokai）
  #       monokai-pro-nvim

  #       # 3. TODO 注释高亮和搜索
  #       todo-comments-nvim

  #       # 4. Spectre：批量查找和替换（支持正则表达式）
  #       nvim-spectre

  #       # 5. DAP (Debug Adapter Protocol) - 调试支持
  #       nvim-dap
  #       nvim-dap-ui

  #       # 6. 数据库支持 - vim-dadbod
  #       vim-dadbod
  #       vim-dadbod-ui
  #       vim-dadbod-completion

  #       # 依赖插件
  #       plenary-nvim # 很多插件的依赖
  #       nvim-web-devicons # 图标支持
  #     ];

  #     # Lua 配置代码
  #     # 用于配置上面添加的插件
  #     luaConfigRC = {
  #       # Monokai Pro 主题配置
  #       monokai-theme = ''
  #         require("monokai-pro").setup({
  #           transparent_background = false,
  #           terminal_colors = true,
  #           devicons = true,
  #           filter = "pro", -- classic | octagon | pro | machine | ristretto | spectrum
  #         })
  #         vim.cmd([[colorscheme monokai-pro]])
  #       '';

  #       # TODO 注释配置
  #       todo-comments = ''
  #         require("todo-comments").setup({
  #           signs = true,
  #           keywords = {
  #             FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
  #             TODO = { icon = " ", color = "info" },
  #             HACK = { icon = " ", color = "warning" },
  #             WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
  #             PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
  #             NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
  #           },
  #         })
  #       '';

  #       # Spectre 批量查找替换配置
  #       spectre = ''
  #         require('spectre').setup({
  #           replace_engine = {
  #             ['sed'] = {
  #               cmd = "sed",
  #               args = nil,
  #             },
  #           },
  #           default = {
  #             find = {
  #               cmd = "rg",
  #               options = {"ignore-case"}
  #             },
  #             replace = {
  #               cmd = "sed"
  #             }
  #           },
  #         })
  #       '';

  #       # DAP 调试配置
  #       dap-config = ''
  #         local dap = require('dap')
  #         -- 设置断点快捷键
  #         vim.keymap.set('n', '<F5>', function() dap.continue() end, { desc = "Debug: Continue" })
  #         vim.keymap.set('n', '<F10>', function() dap.step_over() end, { desc = "Debug: Step Over" })
  #         vim.keymap.set('n', '<F11>', function() dap.step_into() end, { desc = "Debug: Step Into" })
  #         vim.keymap.set('n', '<F12>', function() dap.step_out() end, { desc = "Debug: Step Out" })
  #         vim.keymap.set('n', '<leader>b', function() dap.toggle_breakpoint() end, { desc = "Debug: Toggle Breakpoint" })
  #       '';

  #       # DAP UI 配置
  #       dap-ui = ''
  #         require("dapui").setup()
  #         local dap, dapui = require("dap"), require("dapui")
  #         dap.listeners.after.event_initialized["dapui_config"] = function()
  #           dapui.open()
  #         end
  #         dap.listeners.before.event_terminated["dapui_config"] = function()
  #           dapui.close()
  #         end
  #         dap.listeners.before.event_exited["dapui_config"] = function()
  #           dapui.close()
  #         end
  #         vim.keymap.set('n', '<leader>du', function() require("dapui").toggle() end, { desc = "Debug: Toggle UI" })
  #       '';

  #       # 数据库 UI 配置
  #       dadbod-ui = ''
  #         vim.g.db_ui_use_nerd_fonts = 1
  #         vim.g.db_ui_show_database_icon = 1
  #         vim.keymap.set('n', '<leader>D', '<cmd>DBUIToggle<cr>', { desc = "Toggle Database UI" })
  #       '';
  #     };
  #   };
  # };
}
