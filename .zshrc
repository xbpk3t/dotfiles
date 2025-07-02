# ===== 基础设置 =====
HISTFILE=~/.zsh_history   # 历史记录文件
HISTSIZE=10000            # 内存中保存的历史数量
SAVEHIST=10000            # 保存到文件的历史数量
setopt INC_APPEND_HISTORY  # 实时追加历史记录
setopt HIST_IGNORE_DUPS    # 忽略重复命令

# ===== 核心别名 =====
alias ..='cd ..'           # 返回上级目录
alias ...='cd ../..'       # 返回上两级目录
alias ll='ls -lh'          # 长列表格式
alias l='ls -lah'          # 详细列表（含隐藏文件）

# 在terminal输入文件名，可以直接用指定IDE打开该文件
alias -s {md,go,json,cs,ts,html,yaml,yml,python,sql}=goland

# ===== 目录操作函数 =====
mkcd() { mkdir -p "$1" && cd "$1" }  # 创建并进入目录

# ===== robbyrussell 风格提示符 =====
# 经典 robbyrussell 样式: ➜  directory-name
PROMPT='%F{green}➜%f  %F{cyan}%1~%f '

# ===== 终端美化 =====
export CLICOLOR=1  # macOS 启用彩色输出
export LSCOLORS=ExFxBxDxCxegedabagacad  # macOS 彩色配置

# Linux/Unix 通用彩色设置
# export LS_COLORS='di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'



# ==== 关键安全设置 ====
#setopt NO_UNSET             # 防止使用未定义变量
#setopt INTERACTIVE_COMMENTS # 允许在命令后添加注释
