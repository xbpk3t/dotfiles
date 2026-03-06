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

  # [nvim plugins]
  #
  #
  # - url: https://github.com/akinsho/toggleterm.nvim
  # # https://mynixos.com/nixpkgs/package/vimPlugins.auto-save-nvim
  # - url: https://github.com/okuuva/auto-save.nvim/

  # - url: https://github.com/ahmedkhalf/project.nvim
  # - url: https://github.com/mistweaverco/kulala.nvim # [7 Amazing Terminal API Tools You Need To Try](https://www.youtube.com/watch?v=eyXxEBZMVQI)
  # - url: https://github.com/jellydn/hurl.nvim/
  # - url: https://github.com/mfussenegger/nvim-dap
  # - url: https://github.com/loctvl842/monokai-pro.nvim
  # - url: https://github.com/yetone/avante.nvim
  # - url: https://github.com/dstein64/nvim-scrollview
  # - url: https://github.com/folke/flash.nvim
  # - url: https://github.com/kylechui/nvim-surround
  # - url: https://github.com/folke/zen-mode.nvim
  # - url: https://github.com/nvim-lualine/lualine.nvim
  #   score: 5
  # - url: https://github.com/ThePrimeagen/harpoon
  # - url: https://github.com/nvim-neo-tree/neo-tree.nvim
  #   score: 5
  # - url: https://github.com/nvim-pack/nvim-spectre
  # - url: https://github.com/nvim-telescope/telescope.nvim
  #   score: 5
  # - url: https://github.com/ibhagwan/fzf-lua

  # MAYBE: [2025-11-13] 研究一下 Telescope 的 advanced usage 以及相关插件
  # PLAN: 把yazi.nvim 直接做到 toggleterm　里面
  config = mkIf cfg.enable {
    #    programs.neovim = {
    #      enable = true;
    #    };

    programs.nvf = {
      # 启用 nvf 程序
      enable = true;

      settings.vim = {
        # 基本信息
        # 什么是 NVF？
        # NVF (Neovim from Flake) 是一个基于 Nix 的模块化 Neovim 配置框架，它提供：
        # - 声明式配置
        # - 可重现的开发环境
        # - 模块化插件管理
        # - 与 Nix 生态系统的深度集成
        # Leader 键
        # 本配置中的 Leader 键默认为 **空格键** (`<Space>`)。
        # ---
        # 启动 Neovim
        # 在终端中输入以下任一命令：
        # ```bash
        # nvim          # 启动 Neovim
        # vim           # 别名，等同于 nvim
        # vi            # 别名，等同于 nvim
        # ```
        # ---
        # 根据您的需求，已成功实现以下 9 个功能：
        # 功能 1: Scratches（临时文件）
        # 类似 IDEA 的 Scratches 功能，用于创建临时文件进行快速测试和笔记。
        # **注意**：由于 scratch.nvim 插件需要特殊配置，当前配置中暂未完全集成。您可以使用以下替代方案：
        # - **状态**：部分实现
        # - **说明**：由于 scratch.nvim 插件需要特殊的构建配置，当前使用 Neovim 内置功能作为替代
        # - **使用方法**：
        #   - `:enew` - 创建新的空缓冲区
        #   - `:e /tmp/scratch.txt` - 创建临时文件
        # 功能 2: Monokai 主题
        # 已启用 Monokai Pro 主题，提供类似 IDEA Monokai 的高亮配色方案。
        # - **状态**：✅ 已完全实现
        # - **插件**：monokai-pro-nvim
        # - **配置**：已启用 Monokai Pro 主题，默认使用 "pro" 变体
        # - **可选变体**：classic, octagon, pro, machine, ristretto, spectrum
        # 功能 3: 文件树 Git 状态
        # - **状态**：✅ 已完全实现
        # - **插件**：neo-tree + gitsigns
        # - **功能**：文件树中显示 Git 状态（新增、修改、删除等）
        # - **快捷键**：`<leader>fe` 切换文件树
        # 功能 4: 最近文件（类似 CMD+E）
        # - **状态**：✅ 已完全实现
        # - **插件**：telescope
        # - **快捷键**：`<leader>fr` 打开最近文件列表
        # - **功能**：快速访问最近编辑的文件
        # 功能 5: 数据库支持
        # - **状态**：✅ 已完全实现
        # - **插件**：vim-dadbod, vim-dadbod-ui, vim-dadbod-completion
        # - **支持的数据库**：MySQL, PostgreSQL, SQLite, MongoDB, Redis 等
        # - **快捷键**：`<leader>D` 打开数据库 UI
        # - **说明**：虽然不如 IDEA 的 DB driver 丰富，但已提供基本的数据库操作功能
        # 功能 6: 批量查找和替换
        # - **状态**：✅ 已完全实现
        # - **插件**：nvim-spectre
        # - **功能**：
        #   - 项目级别批量查找
        #   - 支持正则表达式
        #   - 批量替换操作
        # - **快捷键**：`<leader>sr` 打开 Spectre
        # 功能 7: TODO 注释过滤
        # - **状态**：✅ 已完全实现
        # - **插件**：todo-comments-nvim
        # - **支持的关键字**：TODO, FIXME, BUG, HACK, WARN, PERF, NOTE
        # - **功能**：
        #   - 自动高亮 TODO 注释
        #   - 搜索所有 TODO 注释
        #   - 自定义关键字和颜色
        # - **快捷键**：`<leader>ft` 搜索 TODO
        # 功能 8: 多项目支持
        # - **状态**：✅ 已完全实现
        # - **插件**：project-nvim
        # - **功能**：
        #   - 自动检测项目根目录
        #   - 记住最近访问的项目
        #   - 快速切换项目
        # - **快捷键**：`<leader>fp` 切换项目
        # 功能 9: 调试支持（断点）
        # - **状态**：✅ 已完全实现
        # - **插件**：nvim-dap, nvim-dap-ui
        # - **功能**：
        #   - 设置/删除断点
        #   - 单步执行（进入、跳过、跳出）
        #   - 查看变量
        #   - 调用堆栈
        #   - 调试 UI
        # - **快捷键**：
        #   - `<F5>` - 继续执行
        #   - `<F10>` - 单步跳过
        #   - `<F11>` - 单步进入
        #   - `<F12>` - 单步跳出
        #   - `<leader>b` - 切换断点
        #   - `<leader>du` - 切换调试 UI
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

        # 快捷键总览
        # 文件操作
        # - `<leader>ff` - 按文件名搜索
        # - `<leader>lg` - 在内容中搜索
        # - `<leader>fe` - 切换文件树
        # - `<leader>fr` - 最近文件
        # 项目管理
        # - `<leader>fp` - 切换项目
        # - `<leader>ft` - 搜索 TODO
        # - `<leader>sr` - 批量查找替换
        # 数据库
        # - `<leader>D` - 数据库 UI
        # 调试
        # - `<F5>` - 继续
        # - `<F10>` - 单步跳过
        # - `<F11>` - 单步进入
        # - `<F12>` - 单步跳出
        # - `<leader>b` - 切换断点
        # - `<leader>du` - 调试 UI
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
          # 自动保存切换（AutoSave.nvim 默认命令 ASToggle）
          {
            key = "<leader>ua";
            mode = ["n"];
            action = "<cmd>ASToggle<cr>";
            desc = "Toggle auto-save";
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
          # 文件浏览器（yazi）
          {
            key = "<leader>fe";
            mode = ["n"];
            action = "<cmd>lua YaziProjectRoot()<cr>";
            desc = "Project explorer (yazi)";
          }
          # 最近文件列表（oldfiles）
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
          # 删除当前文件（rm + 关闭缓冲区）
          {
            key = "<leader>fd";
            mode = ["n"];
            action = "<cmd>DeleteCurrentFile<cr>";
            desc = "Delete file from disk";
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
          # telescope: 当前文档结构
          {
            key = "<leader>ls";
            mode = ["n"];
            action = "<cmd>lua __nvf_lsp_document_symbols()<cr>";
            desc = "Document symbols";
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
          # LSP 导航：定义/声明/引用/实现
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

        # 主题配置（已注释，可根据需要启用）
        # theme = {
        #   enable = true;
        #   name = "nord";
        #   style = "dark";
        #   transparent = true;
        # };

        # 启用 Telescope 模糊查找器（必需的核心插件）
        # Telescope（模糊查找器）
        # 强大的模糊查找工具，支持：
        # - 文件搜索
        # - 内容搜索
        # - 最近文件
        # - Git 文件
        # - 命令历史
        # - 帮助文档
        # 核心功能补充：最近文件（类似 CMD+E）
        # 使用 Telescope 快速访问最近编辑的文件。
        # **快捷键**：`<leader>fr`
        telescope.enable = true;

        # 启用拼写检查
        spellcheck = {
          enable = false;
        };

        # LSP（语言服务器协议）配置
        # LSP（语言服务器协议）
        # 已启用以下语言的 LSP 支持：
        # - **Nix** - Nix 语言
        # - **C/C++** - Clang
        # - **Python** - Python
        # - **Markdown** - Markdown
        # - **TypeScript/JavaScript** - TS
        # - **HTML** - HTML
        # 功能：
        # - 代码补全
        # - 语法检查
        # - 跳转到定义
        # - 查找引用
        # - 重命名符号
        # - 保存时自动格式化
        lsp = {
          # 启用 LSP 支持
          enable = true;
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
        # https://notashelf.github.io/nvf/index.xhtml#ch-languages
        languages = {
          # 启用代码格式化
          enableFormat = true;
          # 启用 Treesitter 语法高亮
          enableTreesitter = true;
          # 启用额外的诊断信息
          enableExtraDiagnostics = true;

          # 各语言的 LSP 支持
          nix.enable = true; # Nix 语言
          go.enable = true;
          lua.enable = true;

          clang.enable = true; # C/C++
          # zig.enable = true; # Zig（已禁用：zig-hook 标记为损坏）
          python.enable = true;
          markdown.enable = true;
          ts.enable = true; # TypeScript/JavaScript
          html.enable = true;
          yaml.enable = true;
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

        # 自动配对括号、引号等（交由 lazy.nvim 版本管理）
        autopairs.nvim-autopairs.enable = false;

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
        # Treesitter
        # 提供更好的语法高亮和代码理解：
        # - 精确的语法高亮
        # - 代码折叠
        # - 增量选择
        # - 上下文显示
        treesitter.context.enable = false;

        # 快捷键绑定辅助工具
        # Which-Key
        # 自动显示可用的快捷键提示。按下 Leader 键后稍等片刻，会显示所有可用的快捷键组合。
        binds = {
          # Which-Key：显示可用的快捷键提示
          whichKey.enable = true;
          # 快捷键速查表
          cheatsheet.enable = true;
        };

        # Git 集成
        # GitSigns
        # 在行号旁显示 Git 变更标记：
        # - `+` 新增行
        # - `~` 修改行
        # - `-` 删除行
        git = {
          # 启用 Git 支持
          enable = true;
          # GitSigns：在行号旁显示 Git 变更标记
          gitsigns.enable = true;
          # 禁用 GitSigns 代码操作（会产生调试信息）
          gitsigns.codeActions.enable = false;
        };

        # 项目管理（支持多项目切换）
        # 多项目支持
        # project-nvim 插件支持管理和切换多个项目。
        # **快捷键**：`<leader>fp` 切换项目
        # 功能：
        # - 自动检测项目根目录（基于 .git、package.json 等）
        # - 记住最近访问的项目
        # - 快速切换项目
        projects.project-nvim.enable = true;

        # 启动页面（Dashboard）
        dashboard.dashboard-nvim.enable = false;

        # 文件树浏览器由 yazi.nvim 接管
        # Neo-tree（文件浏览器）
        # 功能丰富的文件浏览器：
        # - 树形目录结构
        # - Git 状态显示
        # - 文件操作（创建、删除、重命名）
        # - 书签功能
        # 文件树 Git 状态
        # Neo-tree 文件浏览器已启用，支持显示 Git 状态：
        # - 🟢 新增文件
        # - 🟡 修改文件
        # - 🔴 删除文件
        # - 📝 未跟踪文件
        # **快捷键**：`<leader>fe` 切换文件树
        filetree.neo-tree.enable = false;

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

        # 会话管理
        session = {
          nvim-session-manager.enable = true;
        };

        # 注释插件
        # TODO: 注释过滤
        # todo-comments 插件自动高亮和搜索代码中的 TODO 注释。
        # **支持的关键字**：
        # - `TODO` - 待办事项
        # - `FIXME` / `BUG` - 需要修复的问题
        # - `HACK` - 临时解决方案
        # - `WARN` / `WARNING` - 警告
        # - `PERF` / `OPTIMIZE` - 性能优化
        # - `NOTE` / `INFO` - 注释说明
        # **快捷键**：`<leader>ft` 搜索所有 TODO 注释
        comments = {
          comment-nvim.enable = true;
        };

        # 技术细节
        # 插件管理方式
        # 本配置使用 nvf 的 `startPlugins` 和 `luaConfigRC` 方式管理插件：
        # ```nix
        # startPlugins = with pkgs.vimPlugins; [
        #   monokai-pro-nvim
        #   todo-comments-nvim
        #   nvim-spectre
        #   # ...
        # ];
        #
        # luaConfigRC = {
        #   monokai-theme = ''
        #     require("monokai-pro").setup({ ... })
        #   '';
        #   # ...
        # };
        # ```
        # 这种方式的优点：
        # - 声明式配置
        # - 可重现性
        # - 与 Nix 生态系统集成
        # - 易于版本控制
        lazy = {
          plugins =
            (with pkgs.vimPlugins; {
              # Monokai Pro 主题
              # 已启用 Monokai Pro 主题，提供类似 IDEA Monokai 的高亮配色方案。
              # 主题变体：
              # - `pro` (默认)
              # - `classic`
              # - `octagon`
              # - `machine`
              # - `ristretto`
              # - `spectrum`
              # **切换主题**：编辑 `home/base/core/nvf.nix` 中的 `filter` 选项。
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

              # 批量查找和替换
              # 使用 Spectre 插件进行项目级别的批量查找和替换，支持正则表达式。
              # **快捷键**：`<leader>sr`
              # **使用步骤**：
              # 1. 按 `<leader>sr` 打开 Spectre
              # 2. 输入搜索内容
              # 3. 输入替换内容
              # 4. 按 `<leader>rc` 执行替换
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

              # 调试支持（DAP）
              # 集成了 nvim-dap 和 nvim-dap-ui，提供类似 IDEA 的调试功能。
              # **调试快捷键**：
              # - `<F5>` - 继续执行
              # - `<F10>` - 单步跳过
              # - `<F11>` - 单步进入
              # - `<F12>` - 单步跳出
              # - `<leader>b` - 切换断点
              # - `<leader>du` - 切换调试 UI
              # **设置断点**：
              # 1. 将光标移到要设置断点的行
              # 2. 按 `<leader>b`
              # 3. 按 `<F5>` 开始调试
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

              "telescope-fzf-native.nvim" = {
                package = telescope-fzf-native-nvim;
                lazy = false;
                after = ''
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
              # 数据库支持
              # 集成了 vim-dadbod 系列插件，支持多种数据库：
              # - MySQL/MariaDB
              # - PostgreSQL
              # - SQLite
              # - MongoDB
              # - Redis
              # **快捷键**：`<leader>D` 打开数据库 UI
              # **连接数据库示例**：
              # ```vim
              # :DB g:db = 'mysql://user:password@localhost/dbname'
              # :DB SELECT * FROM users;
              # ```
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

              # "nvim-web-devicons" = {
              #   package = nvim-web-devicons;
              #   lazy = true;
              # };
              #
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

              # "neoscroll.nvim" = {
              #   package = neoscroll-nvim;
              #   event = ["BufReadPost"];
              #   after = ''
              #     local neoscroll = require("neoscroll")
              #     neoscroll.setup({
              #       hide_cursor = true,
              #       stop_eof = true,
              #       respect_scrolloff = false,
              #       performance_mode = false,
              #       easing_function = "cubic",
              #       duration_multiplier = 1.15,
              #       mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
              #     })
              #   '';
              # };
              #
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
