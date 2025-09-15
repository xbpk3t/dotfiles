{pkgs, ...}: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # 基本设置
    opts = {
      # 显示设置
      number = true; # 显示行号
      relativenumber = false; # 显示相对行号
      cursorline = true; # 高亮当前行
      cursorcolumn = true; # 高亮当前列
      ruler = true; # 显示标尺
      laststatus = 2; # 总是显示状态行
      showcmd = true; # 显示输入的命令
      showmode = true; # 显示当前模式
      wrap = true; # 自动换行
      linebreak = true; # 在单词边界换行
      scrolloff = 3; # 光标距离窗口顶部和底部的行数
      sidescrolloff = 5; # 水平滚动时保持5个字符的屏幕边缘
      colorcolumn = "80"; # 在第80列显示标尺线

      # 缩进和制表符设置
      autoindent = true; # 自动缩进
      smartindent = true; # 智能缩进
      cindent = true; # C语言风格缩进
      tabstop = 4; # Tab宽度为4个空格
      expandtab = true; # 将Tab转换为空格
      shiftwidth = 4; # 缩进宽度为4个空格
      softtabstop = 4; # 设置软Tab宽度
      shiftround = true; # 缩进时对齐到shiftwidth的倍数

      # 搜索设置
      ignorecase = true; # 搜索时不区分大小写
      smartcase = true; # 如果有大小写字母则搜索时区分大小写
      hlsearch = true; # 高亮显示搜索结果
      incsearch = true; # 输入搜索内容时即时搜索
      wrapscan = true; # 搜索到文件末尾时重新从开头搜索

      # 匹配和括号设置
      showmatch = true; # 显示匹配的括号
      matchtime = 2; # 括号匹配高亮时间（十分之一秒）

      # 命令行设置
      wildmenu = true; # 增强的命令行模式补全
      wildmode = "longest:full,full"; # 命令行补全模式

      # 编码设置
      encoding = "utf-8"; # Vim内部使用的字符编码
      fileencoding = "utf-8"; # 当前编辑文件的字符编码
      fileformat = "unix"; # 文件格式

      # 基本设置
      compatible = false; # 不兼容vi模式
      backspace = "indent,eol,start"; # 退格键可以删除任何字符
      history = 1000; # 命令历史记录数量
      undolevels = 1000; # 撤销级别
      mouse = "a"; # 启用鼠标支持
      clipboard = "unnamed"; # 使用系统剪贴板
      autoread = true; # 文件在外部被修改时自动重新读取
      confirm = true; # 退出前确认保存
      hidden = true; # 允许在有未保存修改时切换缓冲区

      # 文件和备份设置
      backup = false; # 不创建备份文件
      writebackup = false; # 写入时不创建备份
      swapfile = false; # 不创建交换文件
      undofile = true; # 启用持久化撤销

      # 性能优化
      lazyredraw = true; # 宏执行时不重绘屏幕
      ttyfast = true; # 快速终端连接
      timeout = true; # 启用超时
      timeoutlen = 1000; # 映射超时时间
      ttimeoutlen = 50; # 键码超时时间

      # 折叠设置
      foldenable = true; # 启用折叠
      foldmethod = "indent"; # 基于缩进的折叠
      foldlevelstart = 10; # 打开文件时的折叠级别
      foldnestmax = 10; # 最大折叠深度
    };

    # 全局变量
    globals = {
      mapleader = ","; # 设置leader键为逗号
    };

    # 键盘映射
    keymaps = [
      # 文件操作
      {
        mode = "n";
        key = "<leader>w";
        action = ":w<CR>";
        options.desc = "保存文件";
      }
      {
        mode = "n";
        key = "<leader>q";
        action = ":q<CR>";
        options.desc = "退出Vim";
      }
      {
        mode = "n";
        key = "<leader>wq";
        action = ":wq<CR>";
        options.desc = "保存并退出";
      }
      {
        mode = "n";
        key = "<leader>x";
        action = ":x<CR>";
        options.desc = "保存并退出（如果有修改）";
      }

      # 编辑操作
      {
        mode = "n";
        key = "<leader>u";
        action = ":undo<CR>";
        options.desc = "撤销更改";
      }
      {
        mode = "n";
        key = "<leader>r";
        action = ":redo<CR>";
        options.desc = "重做更改";
      }
      {
        mode = "n";
        key = "<C-a>";
        action = "ggVG";
        options.desc = "全选";
      }
      {
        mode = "v";
        key = "<C-c>";
        action = "\"+y";
        options.desc = "复制到系统剪贴板";
      }
      {
        mode = "n";
        key = "<C-v>";
        action = "\"+p";
        options.desc = "从系统剪贴板粘贴";
      }

      # 搜索和替换
      {
        mode = "n";
        key = "<leader>h";
        action = ":nohlsearch<CR>";
        options.desc = "取消搜索高亮";
      }

      # 窗口操作
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options.desc = "切换到左窗口";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options.desc = "切换到下窗口";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options.desc = "切换到上窗口";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options.desc = "切换到右窗口";
      }

      # 缓冲区操作
      {
        mode = "n";
        key = "<leader>bn";
        action = ":bnext<CR>";
        options.desc = "下一个缓冲区";
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = ":bprevious<CR>";
        options.desc = "上一个缓冲区";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = ":bdelete<CR>";
        options.desc = "删除当前缓冲区";
      }

      # 标签页操作
      {
        mode = "n";
        key = "<leader>tn";
        action = ":tabnew<CR>";
        options.desc = "新建标签页";
      }
      {
        mode = "n";
        key = "<leader>tc";
        action = ":tabclose<CR>";
        options.desc = "关闭标签页";
      }
      {
        mode = "n";
        key = "<leader>to";
        action = ":tabonly<CR>";
        options.desc = "只保留当前标签页";
      }

      # 文件树操作
      {
        mode = "n";
        key = "<leader>e";
        action = ":NvimTreeToggle<CR>";
        options.desc = "切换文件树";
      }
      {
        mode = "n";
        key = "<leader>o";
        action = ":NvimTreeFocus<CR>";
        options.desc = "聚焦文件树";
      }

      # LSP 操作
      {
        mode = "n";
        key = "gd";
        action = "<cmd>lua vim.lsp.buf.definition()<CR>";
        options.desc = "跳转到定义";
      }
      {
        mode = "n";
        key = "gr";
        action = "<cmd>lua vim.lsp.buf.references()<CR>";
        options.desc = "查找引用";
      }
      {
        mode = "n";
        key = "K";
        action = "<cmd>lua vim.lsp.buf.hover()<CR>";
        options.desc = "显示悬停信息";
      }
      {
        mode = "n";
        key = "<leader>rn";
        action = "<cmd>lua vim.lsp.buf.rename()<CR>";
        options.desc = "重命名";
      }
      {
        mode = "n";
        key = "<leader>ca";
        action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
        options.desc = "代码操作";
      }

      # Git 操作
      {
        mode = "n";
        key = "<leader>gs";
        action = ":Gitsigns stage_hunk<CR>";
        options.desc = "暂存当前块";
      }
      {
        mode = "n";
        key = "<leader>gu";
        action = ":Gitsigns undo_stage_hunk<CR>";
        options.desc = "撤销暂存";
      }
      {
        mode = "n";
        key = "<leader>gp";
        action = ":Gitsigns preview_hunk<CR>";
        options.desc = "预览更改";
      }
    ];

    # 自动命令
    autoCmd = [
      {
        event = "BufWritePre";
        pattern = "*";
        command = "%s/\\s\\+$//e";
        desc = "自动删除行尾空格";
      }
      {
        event = "BufReadPost";
        pattern = "*";
        command = ''if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif'';
        desc = "记住上次编辑位置";
      }
    ];

    # 安装常用插件
    plugins = {
      # 图标支持 (必须显式启用)
      web-devicons.enable = true;

      # 文件树插件，支持 Git 状态显示
      nvim-tree = {
        enable = true;
        openOnSetup = false; # 启动时不自动打开
        settings = {
          git.enable = true; # 启用 Git 集成
        };
      };

      # 语法高亮和代码解析
      treesitter = {
        enable = true;
        settings = {
          ensure_installed = ["c" "lua" "python" "javascript" "nix" "bash" "json" "yaml"];
          indent.enable = true;
          highlight.enable = true;
        };
      };

      # 状态栏美化
      lualine = {
        enable = true;
        settings = {
          options = {
            theme = "auto"; # 自动适配主题
            component_separators = {
              left = "";
              right = "";
            };
            section_separators = {
              left = "";
              right = "";
            };
          };
        };
      };

      # LSP 支持
      lsp = {
        enable = true;
        servers = {
          # Nix 语言服务器
          nil_ls.enable = true;
          # Python 语言服务器
          pyright.enable = true;
          # JavaScript/TypeScript 语言服务器
          ts_ls.enable = true;
          # Lua 语言服务器
          lua_ls.enable = true;
          # Bash 语言服务器
          bashls.enable = true;
        };
      };

      # 自动补全
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          sources = [
            {name = "nvim_lsp";}
            {name = "luasnip";}
            {name = "buffer";}
            {name = "path";}
          ];
          mapping = {
            "<C-b>" = "cmp.mapping.scroll_docs(-4)";
            "<C-f>" = "cmp.mapping.scroll_docs(4)";
            "<C-Space>" = "cmp.mapping.complete()";
            "<C-e>" = "cmp.mapping.abort()";
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
          };
        };
      };

      # 代码片段
      luasnip.enable = true;

      # Git 集成
      gitsigns = {
        enable = true;
        settings = {
          signs = {
            add.text = "+";
            change.text = "~";
            delete.text = "_";
            topdelete.text = "‾";
            changedelete.text = "~";
          };
        };
      };

      # 模糊查找
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
        };
      };

      # 缩进线
      indent-blankline = {
        enable = true;
        settings = {
          indent = {
            char = "|"; # 使用简单的竖线字符，宽度为 1
          };
          scope = {
            enabled = true;
            char = "|"; # 作用域也使用相同字符
          };
        };
      };

      # 括号匹配高亮
      rainbow-delimiters.enable = true;

      # 自动配对括号
      nvim-autopairs.enable = true;

      # 注释插件
      comment.enable = true;

      # 终端集成
      toggleterm = {
        enable = true;
        settings = {
          size = 20;
          open_mapping = "[[<c-\\>]]";
          hide_numbers = true;
          shade_filetypes = [];
          shade_terminals = true;
          shading_factor = 2;
          start_in_insert = true;
          insert_mappings = true;
          persist_size = true;
          direction = "float";
          close_on_exit = true;
          shell = "bash";
        };
      };
    };

    # 额外插件（如果需要自定义插件）
    extraPlugins = with pkgs.vimPlugins; [
      vim-sensible # 提供合理的默认配置
      # vim-commentary 已被 comment.nvim 替代
    ];

    # 额外配置
    extraConfigVim = ''
      " 中文支持增强设置
      set ambiwidth=double
      set formatoptions+=mM
      set nobomb

      " 忽略的文件类型
      set wildignore=*.o,*.obj,*.pyc,*.swp,*.bak,*.class

      " 文件编码检测顺序
      set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936,latin1
      set fileformats=unix,dos,mac

      " 撤销文件目录
      set undodir=~/.vim/undodir
    '';
  };
}
