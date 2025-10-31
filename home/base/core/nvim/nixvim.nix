{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.tui.nixvim;
in {
  options.modules.tui.nixvim = {
    enable = lib.mkEnableOption "Enable Nixvim (for Vim)";
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      defaultEditor = true;

      # 创建 vim 和 vi 命令别名指向 nvim
      viAlias = true;
      vimAlias = true;

      # 启用 Node.js 支持（某些插件需要）
      extraPackages = with pkgs; [nodejs];

      # 基础编辑器选项
      opts = {
        number = true; # 显示行号
        cursorline = true; # 高亮当前行
        expandtab = true; # Tab转空格
        tabstop = 2; # Tab宽度
        shiftwidth = 2; # 缩进宽度
        ignorecase = true; # 搜索忽略大小写
        smartcase = true; # 智能大小写搜索
        wrap = true; # 禁用自动换行
        spell = false; # 启用拼写检查
      };

      # 自定义快捷键映射
      keymaps = [
        # 插入模式下使用 jk 快速退出到普通模式
        {
          mode = "i";
          key = "jk";
          action = "<ESC>";
          options = {
            desc = "Exit insert mode";
          };
        }
        # 清除搜索高亮
        {
          mode = "n";
          key = "<leader>nh";
          action = ":nohl<CR>";
          options = {
            desc = "Clear search highlights";
          };
        }
        # 使用 Telescope 按文件名搜索文件
        {
          mode = "n";
          key = "<leader>ff";
          action = "<cmd>Telescope find_files<cr>";
          options = {
            desc = "Search files by name";
          };
        }
        # 使用 Telescope 在文件内容中搜索（实时 grep）
        {
          mode = "n";
          key = "<leader>lg";
          action = "<cmd>Telescope live_grep<cr>";
          options = {
            desc = "Search files by contents";
          };
        }
        # 切换文件浏览器（Neo-tree）
        {
          mode = "n";
          key = "<leader>fe";
          action = "<cmd>Neotree toggle<cr>";
          options = {
            desc = "File browser toggle";
          };
        }
        # 类似 CMD+E：打开最近编辑的文件列表
        {
          mode = "n";
          key = "<leader>fr";
          action = "<cmd>Telescope oldfiles<cr>";
          options = {
            desc = "Recent files (like CMD+E in IDEA)";
          };
        }
        # 插入模式下的方向键映射（Ctrl + hjkl）
        {
          mode = "i";
          key = "<C-h>";
          action = "<Left>";
          options = {
            desc = "Move left in insert mode";
          };
        }
        {
          mode = "i";
          key = "<C-j>";
          action = "<Down>";
          options = {
            desc = "Move down in insert mode";
          };
        }
        {
          mode = "i";
          key = "<C-k>";
          action = "<Up>";
          options = {
            desc = "Move up in insert mode";
          };
        }
        {
          mode = "i";
          key = "<C-l>";
          action = "<Right>";
          options = {
            desc = "Move right in insert mode";
          };
        }
        # 项目切换快捷键
        {
          mode = "n";
          key = "<leader>fp";
          action = "<cmd>Telescope projects<cr>";
          options = {
            desc = "Switch between projects";
          };
        }
        {
          mode = "n";
          key = "<leader>ft";
          action = "<cmd>TodoTelescope<cr>";
          options = {
            desc = "Find TODO comments";
          };
        }
        # 批量查找和替换
        {
          mode = "n";
          key = "<leader>sr";
          action = "<cmd>lua require('spectre').open()<cr>";
          options = {
            desc = "Open Spectre for search and replace";
          };
        }
        # 设置断点快捷键
        {
          mode = "n";
          key = "<F5>";
          action = "function() require('dap').continue() end";
          options = {
            desc = "Debug: Continue";
          };
        }
        {
          mode = "n";
          key = "<F10>";
          action = "function() require('dap').step_over() end";
          options = {
            desc = "Debug: Step Over";
          };
        }
        {
          mode = "n";
          key = "<F11>";
          action = "function() require('dap').step_into() end";
          options = {
            desc = "Debug: Step Into";
          };
        }
        {
          mode = "n";
          key = "<F12>";
          action = "function() require('dap').step_out() end";
          options = {
            desc = "Debug: Step Out";
          };
        }
        {
          mode = "n";
          key = "<leader>b";
          action = "function() require('dap').toggle_breakpoint() end";
          options = {
            desc = "Debug: Toggle Breakpoint";
          };
        }
        {
          mode = "n";
          key = "<leader>du";
          action = "function() require('dapui').toggle() end";
          options = {
            desc = "Debug: Toggle UI";
          };
        }
        {
          mode = "n";
          key = "<leader>D";
          action = "<cmd>DBUIToggle<cr>";
          options = {
            desc = "Toggle Database UI";
          };
        }
      ];

      # 推荐的插件（完整迁移版）
      plugins = {
        # 核心插件
        web-devicons.enable = true; # 文件类型图标
        treesitter = {
          enable = true;
          settings = {
            ensureInstalled = [
              "nix"
              "c"
              "cpp"
              "python"
              "markdown"
              "typescript"
              "javascript"
              "html"
            ];
          };
        };
        cmp.enable = true; # 自动补全
        luasnip.enable = true; # 代码片段支持
        nvim-autopairs.enable = true; # 自动配对括号、引号等

        # LSP 相关
        lsp = {
          enable = true;
          servers = {
            nil_ls = {
              # Nix 语言服务器
              enable = true;
            };
            clangd = {
              # C/C++ 语言服务器
              enable = true;
            };
            pyright = {
              # Python 语言服务器
              enable = true;
            };
            marksman = {
              # Markdown 语言服务器
              enable = true;
            };
            tsserver = {
              # TS/JS 语言服务器
              enable = true;
            };
            html = {
              # HTML 语言服务器
              enable = true;
            };
          };
        };
        lsp-format.enable = true; # 保存文件时自动格式化
        lspkind.enable = false; # LSP 图标支持
        # lightbulb.enable = true; # 代码操作提示灯泡 - NOT AVAILABLE IN NIXVIM
        trouble.enable = true; # Trouble：更好的诊断列表
        lsp-signature.enable = true; # 函数签名提示

        # 搜索和文件浏览
        telescope.enable = true; # Telescope 模糊查找器
        neo-tree = {
          # 文件树浏览器
          enable = true;
        };
        #      project = { # 项目管理 - NOT AVAILABLE IN NIXVIM
        #        enable = true;
        #      };
        dashboard = {
          # 启动页面
          enable = true;
        };

        # 视觉增强
        #      nvim-cursorline.enable = true; # 当前行高亮 - NOT AVAILABLE IN NIXVIM
        #      cinnamon.enable = true; # 平滑滚动动画
        fidget.enable = true; # LSP 进度显示
        #      highlight-undo.enable = true; # 撤销操作高亮
        indent-blankline = {
          # 缩进参考线
          enable = true;
        };
        illuminate.enable = true; # 高亮当前光标下的相同单词
        colorizer.enable = true; # 颜色代码高亮显示
        smartcolumn = {
          # 智能列标记（超过一定宽度时显示）
          enable = true;
        };

        # UI 增强
        noice.enable = true; # Noice：更好的命令行、消息和通知 UI
        navbuddy.enable = true; # 代码导航器
        fastaction.enable = true; # 快速操作 UI
        bufferline.enable = true; # 顶部标签栏
        treesitter-context.enable = true; # Treesitter 上下文显示（显示当前函数/类名）

        # 快捷键和辅助工具
        which-key.enable = true; # Which-Key：显示可用的快捷键提示
        #      cheatsheet.enable = true; # 快捷键速查表

        # Git 集成
        gitsigns = {
          # GitSigns：在行号旁显示 Git 变更标记
          enable = true;
          settings = {
            enableCodeActions = false; # 禁用 GitSigns 代码操作（会产生调试信息）
          };
        };

        # 会话管理
        session-manager.enable = false; # 会话管理（已禁用）

        # 注释插件
        comment.enable = true; # 注释插件

        # 通知系统
        notify = {
          enable = true;
          backgroundColour = "#f38ba8";
        };

        # 实用工具插件
        #      icon-picker.enable = true; # 图标选择器
        #      surround.enable = true; # 环绕操作（快速添加/修改括号、引号等）
        #      diffview.enable = true; # Git diff 查看器
        #      hop.enable = true; # Hop：快速跳转到任意位置
        #      leap.enable = true; # Leap：另一种快速跳转方式

        # 自定义插件
        #      monokai-pro = {  # NOT AVAILABLE IN NIXVIM
        #        enable = true;
        #      };
        todo-comments = {
          enable = true;
        };
        spectre = {
          enable = true;
        };
        dap = {
          enable = true;
        };
        dap-ui = {
          enable = true;
        };
        #      dadbod = {
        #        enable = true;
        #      };
        #      dadbod-ui = {
        #        enable = true;
        #      };
      };

      # Lua 配置代码
      extraConfigLua = ''
        -- TODO 注释配置
        require("todo-comments").setup({
          signs = true,
          keywords = {
            FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
            TODO = { icon = " ", color = "info" },
            HACK = { icon = " ", color = "warning" },
            WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
            PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
            NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
          },
        })

        -- Spectre 配置
        require('spectre').setup({
          replace_engine = {
            ['sed'] = {
              cmd = "sed",
              args = nil,
            },
          },
          default = {
            find = {
              cmd = "rg",
              options = {"ignore-case"}
            },
            replace = {
              cmd = "sed"
            }
          },
        })

        -- DAP UI 配置
        require("dapui").setup()
        local dap, dapui = require("dap"), require("dapui")
        dap.listeners.after.event_initialized["dapui_config"] = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
          dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
          dapui.close()
        end

        -- 数据库 UI 配置
        vim.g.db_ui_use_nerd_fonts = 1
        vim.g.db_ui_show_database_icon = 1
      '';
    };
  };
}
