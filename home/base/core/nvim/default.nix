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
          # 启用自动换行并在单词边界断行，保持缩进
          wrap = true;
          linebreak = true;
          breakindent = true;
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
          {
            key = "<C-`>";
            mode = ["n"];
            action = "<cmd>Telescope oldfiles<cr>";
            desc = "Recent files via Ctrl+`";
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
        autocomplete.nvim-cmp.enable = true;

        # 代码片段支持
        # [2025-11-07] 很干扰，所以注释掉
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
          surround.enable = true;
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

        # 自定义插件列表
        # https://mynixos.com/nixpkgs/packages/vimPlugins
        startPlugins =
          (with pkgs.vimPlugins; [
            monokai-pro-nvim
            todo-comments-nvim
            nvim-spectre
            nvim-dap
            nvim-dap-ui
            lazygit-nvim

            # https://github.com/ThePrimeagen/harpoon
            # https://mynixos.com/nixpkgs/package/vimPlugins.harpoon
            harpoon
            # https://mynixos.com/nixpkgs/package/vimPlugins.kulala-nvim
            # kulala-nvim
            # https://mynixos.com/nixpkgs/package/vimPlugins.hurl-nvim
            # https://mynixos.com/nixpkgs/package/hurl
            # hurl-nvim

            telescope-fzf-native-nvim
            # https://github.com/someone-stole-my-name/yaml-companion.nvim
            # yaml-companion-nvim
            vim-dadbod
            vim-dadbod-ui
            vim-dadbod-completion

            plenary-nvim
            nui-nvim
            nvim-web-devicons
            nvim-surround
            flash-nvim
            nvim-scrollview
            neoscroll-nvim
            fzf-lua
            avante-nvim
            # https://github.com/folke/zen-mode.nvim
            # zen-mode-nvim
            lualine-nvim
          ])
          ++ [scratchNvim];

        # Lua 配置代码
        # 用于配置上面添加的插件
        luaConfigRC = {
          auto-save = builtins.readFile ./auto-save.lua;
          # kulala = builtins.readFile ./kulala.lua;
          # hurl = builtins.readFile ./hurl.lua;
          monokai-theme = builtins.readFile ./theme.lua;
          telescope_extensions = builtins.readFile ./telescope-fzf.lua;
          todo-comments = builtins.readFile ./todo-comments.lua;
          spectre = builtins.readFile ./spectre.lua;
          dap-config = builtins.readFile ./dap-config.lua;
          dap-ui = builtins.readFile ./dap-ui.lua;
          dadbod-ui = builtins.readFile ./dadbod-ui.lua;
          lazygit = builtins.readFile ./lazygit.lua;
          harpoon = builtins.readFile ./harpoon.lua;
          scratch = builtins.readFile ./scratch.lua;
          neotree = builtins.readFile ./neotree.lua;
          # yaml_companion = builtins.readFile ./yaml-companion.lua;
          nvim_surround = builtins.readFile ./nvim-surround.lua;
          flash = builtins.readFile ./flash.lua;
          scrollview = builtins.readFile ./scrollview.lua;
          neoscroll = builtins.readFile ./neoscroll.lua;
          fzf_lua = builtins.readFile ./fzf-lua.lua;
          avante = builtins.readFile ./avante.lua;
          # zen_mode = builtins.readFile ./zen-mode.lua;
          lualine = builtins.readFile ./lualine.lua;
          treesitter = builtins.readFile ./treesitter.lua;
        };
      };
    };
  };
}
