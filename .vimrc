" [Vim配置文件优化与最佳实践指南 - OSCHINA - 中文开源技术交流社区](https://my.oschina.net/emacs_8870012/blog/17471151)


" ===== 显示设置 =====
set number                            " 显示行号
set relativenumber                    " 显示相对行号
set cursorline                        " 高亮当前行
set cursorcolumn                      " 高亮当前列
set ruler                             " 显示标尺
set laststatus=2                      " 总是显示状态行
set showcmd                           " 显示输入的命令
set showmode                          " 显示当前模式
set wrap                              " 自动换行
set linebreak                         " 在单词边界换行
set scrolloff=3                       " 光标距离窗口顶部和底部的行数
set sidescrolloff=5                   " 水平滚动时保持5个字符的屏幕边缘
set colorcolumn=80                    " 在第80列显示标尺线

" ===== 缩进和制表符设置 =====
set autoindent                        " 自动缩进
set smartindent                       " 智能缩进
set cindent                           " C语言风格缩进
set tabstop=4                         " Tab宽度为4个空格
set expandtab                         " 将Tab转换为空格
set shiftwidth=4                      " 缩进宽度为4个空格
set softtabstop=4                     " 设置软Tab宽度
set shiftround                        " 缩进时对齐到shiftwidth的倍数

" ===== 搜索设置 =====
set ignorecase                        " 搜索时不区分大小写
set smartcase                         " 如果有大小写字母则搜索时区分大小写
set hlsearch                          " 高亮显示搜索结果
set incsearch                         " 输入搜索内容时即时搜索
set wrapscan                          " 搜索到文件末尾时重新从开头搜索

" ===== 匹配和括号设置 =====
set showmatch                         " 显示匹配的括号
set matchtime=2                       " 括号匹配高亮时间（十分之一秒）

" ===== 命令行设置 =====
set wildmenu                          " 增强的命令行模式补全
set wildmode=longest:full,full        " 命令行补全模式
set wildignore=*.o,*.obj,*.pyc,*.swp,*.bak,*.class  " 忽略的文件类型

" ===== 编码设置 =====
" 强制设置环境变量以确保UTF-8支持
if empty($LANG)
    let $LANG = 'en_US.UTF-8'
endif
if empty($LC_ALL)
    let $LC_ALL = 'en_US.UTF-8'
endif

set encoding=utf-8                    " Vim内部使用的字符编码
set termencoding=utf-8                " 终端的字符编码
set fileencoding=utf-8                " 当前编辑文件的字符编码
set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936,latin1  " 自动检测文件编码的顺序
set fileformat=unix                   " 文件格式，支持unix/dos/mac
set fileformats=unix,dos,mac          " 自动检测文件格式的顺序

" 确保终端支持UTF-8和中文显示
if &term =~ "xterm" || &term =~ "screen"
    set t_Co=256
endif

" 中文支持增强设置
set ambiwidth=double                  " 设置双宽字符的宽度处理
set formatoptions+=mM                 " 正确处理中文换行
set nobomb                            " 不使用BOM标记

" ===== 基本设置 =====
set nocompatible                      " 不兼容vi模式
set backspace=indent,eol,start        " 退格键可以删除任何字符
set history=1000                      " 命令历史记录数量
set undolevels=1000                   " 撤销级别
set mouse=a                           " 启用鼠标支持
set clipboard=unnamed                 " 使用系统剪贴板
set autoread                          " 文件在外部被修改时自动重新读取
set confirm                           " 退出前确认保存
set hidden                            " 允许在有未保存修改时切换缓冲区

" ===== 文件和备份设置 =====
set nobackup                          " 不创建备份文件
set nowritebackup                     " 写入时不创建备份
set noswapfile                        " 不创建交换文件
set undofile                          " 启用持久化撤销
set undodir=~/.vim/undodir            " 撤销文件目录
if !isdirectory(&undodir)
    call mkdir(&undodir, 'p')
endif

" ===== 性能优化 =====
set lazyredraw                        " 宏执行时不重绘屏幕
set ttyfast                           " 快速终端连接
set timeout                           " 启用超时
set timeoutlen=1000                   " 映射超时时间
set ttimeoutlen=50                    " 键码超时时间

" ===== 折叠设置 =====
set foldenable                        " 启用折叠
set foldmethod=indent                 " 基于缩进的折叠
set foldlevelstart=10                 " 打开文件时的折叠级别
set foldnestmax=10                    " 最大折叠深度

" ===== 状态栏设置 =====
set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [POS=%l,%v][%p%%]\ %{strftime(\"%d/%m/%y\ -\ %H:%M\")}

" ===== 语法高亮和主题 =====
syntax enable                         " 启用语法高亮
filetype plugin indent on            " 启用文件类型检测、插件和缩进




" 插件管理



" 设置颜色方案
colorscheme desert

" 或者自定义颜色方案
highlight Normal guifg=white guibg=black
highlight Comment guifg=green
highlight Statement guifg=yellow
highlight PreProc guifg=blue
highlight SpecialComment guifg=red



" ===== 快捷键映射 =====
let mapleader = ","                   " 设置leader键为逗号

" 文件操作
nnoremap <leader>w :w<CR>             " 保存文件
nnoremap <leader>q :q<CR>             " 退出Vim
nnoremap <leader>wq :wq<CR>           " 保存并退出
nnoremap <leader>x :x<CR>             " 保存并退出（如果有修改）

" 编辑操作
nnoremap <leader>u :undo<CR>          " 撤销更改
nnoremap <leader>r :redo<CR>          " 重做更改
nnoremap <C-a> ggVG                   " 全选
vnoremap <C-c> "+y                    " 复制到系统剪贴板
nnoremap <C-v> "+p                    " 从系统剪贴板粘贴

" 搜索和替换
nnoremap <leader>h :nohlsearch<CR>    " 取消搜索高亮
nnoremap <leader>s :%s/\<<C-r><C-w>\>//g<Left><Left>  " 替换当前单词

" 窗口操作
nnoremap <C-h> <C-w>h                 " 切换到左窗口
nnoremap <C-j> <C-w>j                 " 切换到下窗口
nnoremap <C-k> <C-w>k                 " 切换到上窗口
nnoremap <C-l> <C-w>l                 " 切换到右窗口

" 缓冲区操作
nnoremap <leader>bn :bnext<CR>        " 下一个缓冲区
nnoremap <leader>bp :bprevious<CR>    " 上一个缓冲区
nnoremap <leader>bd :bdelete<CR>      " 删除当前缓冲区

" 标签页操作
nnoremap <leader>tn :tabnew<CR>       " 新建标签页
nnoremap <leader>tc :tabclose<CR>     " 关闭标签页
nnoremap <leader>to :tabonly<CR>      " 只保留当前标签页

" 插件操作
nnoremap <leader>n :NERDTreeToggle<CR> " 打开或关闭NERDTree

" ===== 自动命令 =====
augroup vimrc_autocmds
    autocmd!
    " 自动删除行尾空格
    autocmd BufWritePre * :%s/\s\+$//e
    " 记住上次编辑位置
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
    " 自动保存折叠状态
    autocmd BufWinLeave *.* mkview
    autocmd BufWinEnter *.* silent loadview
augroup END
