{pkgs, ...}: {

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # 基本设置
    opts = {
      # 显示设置
      number = true;                    # 显示行号
      relativenumber = true;            # 显示相对行号
      cursorline = true;                # 高亮当前行
      cursorcolumn = true;              # 高亮当前列
      ruler = true;                     # 显示标尺
      laststatus = 2;                   # 总是显示状态行
      showcmd = true;                   # 显示输入的命令
      showmode = true;                  # 显示当前模式
      wrap = true;                      # 自动换行
      linebreak = true;                 # 在单词边界换行
      scrolloff = 3;                    # 光标距离窗口顶部和底部的行数
      sidescrolloff = 5;                # 水平滚动时保持5个字符的屏幕边缘
      colorcolumn = "80";               # 在第80列显示标尺线

      # 缩进和制表符设置
      autoindent = true;                # 自动缩进
      smartindent = true;               # 智能缩进
      cindent = true;                   # C语言风格缩进
      tabstop = 4;                      # Tab宽度为4个空格
      expandtab = true;                 # 将Tab转换为空格
      shiftwidth = 4;                   # 缩进宽度为4个空格
      softtabstop = 4;                  # 设置软Tab宽度
      shiftround = true;                # 缩进时对齐到shiftwidth的倍数

      # 搜索设置
      ignorecase = true;                # 搜索时不区分大小写
      smartcase = true;                 # 如果有大小写字母则搜索时区分大小写
      hlsearch = true;                  # 高亮显示搜索结果
      incsearch = true;                 # 输入搜索内容时即时搜索
      wrapscan = true;                  # 搜索到文件末尾时重新从开头搜索

      # 匹配和括号设置
      showmatch = true;                 # 显示匹配的括号
      matchtime = 2;                    # 括号匹配高亮时间（十分之一秒）

      # 命令行设置
      wildmenu = true;                  # 增强的命令行模式补全
      wildmode = "longest:full,full";   # 命令行补全模式

      # 编码设置
      encoding = "utf-8";               # Vim内部使用的字符编码
      fileencoding = "utf-8";           # 当前编辑文件的字符编码
      fileformat = "unix";              # 文件格式

      # 基本设置
      compatible = false;               # 不兼容vi模式
      backspace = "indent,eol,start";   # 退格键可以删除任何字符
      history = 1000;                   # 命令历史记录数量
      undolevels = 1000;                # 撤销级别
      mouse = "a";                      # 启用鼠标支持
      clipboard = "unnamed";            # 使用系统剪贴板
      autoread = true;                  # 文件在外部被修改时自动重新读取
      confirm = true;                   # 退出前确认保存
      hidden = true;                    # 允许在有未保存修改时切换缓冲区

      # 文件和备份设置
      backup = false;                   # 不创建备份文件
      writebackup = false;              # 写入时不创建备份
      swapfile = false;                 # 不创建交换文件
      undofile = true;                  # 启用持久化撤销

      # 性能优化
      lazyredraw = true;                # 宏执行时不重绘屏幕
      ttyfast = true;                   # 快速终端连接
      timeout = true;                   # 启用超时
      timeoutlen = 1000;                # 映射超时时间
      ttimeoutlen = 50;                 # 键码超时时间

      # 折叠设置
      foldenable = true;                # 启用折叠
      foldmethod = "indent";            # 基于缩进的折叠
      foldlevelstart = 10;              # 打开文件时的折叠级别
      foldnestmax = 10;                 # 最大折叠深度
    };

    # 全局变量
    globals = {
      mapleader = ",";                  # 设置leader键为逗号
    };

    # 颜色主题
    colorschemes.base16 = {
      enable = true;
      colorscheme = "default-dark";
    };

    # 键盘映射
    keymaps = [
      # 文件操作
      { mode = "n"; key = "<leader>w"; action = ":w<CR>"; options.desc = "保存文件"; }
      { mode = "n"; key = "<leader>q"; action = ":q<CR>"; options.desc = "退出Vim"; }
      { mode = "n"; key = "<leader>wq"; action = ":wq<CR>"; options.desc = "保存并退出"; }
      { mode = "n"; key = "<leader>x"; action = ":x<CR>"; options.desc = "保存并退出（如果有修改）"; }

      # 编辑操作
      { mode = "n"; key = "<leader>u"; action = ":undo<CR>"; options.desc = "撤销更改"; }
      { mode = "n"; key = "<leader>r"; action = ":redo<CR>"; options.desc = "重做更改"; }
      { mode = "n"; key = "<C-a>"; action = "ggVG"; options.desc = "全选"; }
      { mode = "v"; key = "<C-c>"; action = "\"+y"; options.desc = "复制到系统剪贴板"; }
      { mode = "n"; key = "<C-v>"; action = "\"+p"; options.desc = "从系统剪贴板粘贴"; }

      # 搜索和替换
      { mode = "n"; key = "<leader>h"; action = ":nohlsearch<CR>"; options.desc = "取消搜索高亮"; }

      # 窗口操作
      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "切换到左窗口"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "切换到下窗口"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "切换到上窗口"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "切换到右窗口"; }

      # 缓冲区操作
      { mode = "n"; key = "<leader>bn"; action = ":bnext<CR>"; options.desc = "下一个缓冲区"; }
      { mode = "n"; key = "<leader>bp"; action = ":bprevious<CR>"; options.desc = "上一个缓冲区"; }
      { mode = "n"; key = "<leader>bd"; action = ":bdelete<CR>"; options.desc = "删除当前缓冲区"; }

      # 标签页操作
      { mode = "n"; key = "<leader>tn"; action = ":tabnew<CR>"; options.desc = "新建标签页"; }
      { mode = "n"; key = "<leader>tc"; action = ":tabclose<CR>"; options.desc = "关闭标签页"; }
      { mode = "n"; key = "<leader>to"; action = ":tabonly<CR>"; options.desc = "只保留当前标签页"; }
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
