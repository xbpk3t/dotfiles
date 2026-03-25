
# ===== 键盘绑定 =====
# 设置键绑定模式
bindkey -e                 # emacs 模式（默认）
# bindkey -v              # vi 模式（如果需要）

# 设置不区分大小写的制表符补全
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|=*' 'l:|=* r:|=*'

# ===== worktrunk shell integration =====
# Home Manager 管理的 ~/.zshrc 是只读 symlink，不能依赖 `wt config shell install`
# 所以这里显式注入 zsh integration，让 `wt switch <branch>` 能自动切目录。
if command -v wt >/dev/null 2>&1; then
  eval "$(command wt config shell init zsh)"
fi

# ===== 文件后缀处理 =====
# zsh 支持 alias -s 功能
alias -s {md,go,json,ts,html,yaml,yml,py,sql}=goland

# ===== eza wrapper (works even without a TTY stdin) =====
unalias ll 2>/dev/null || true
ll() {
  if [[ $# -eq 0 ]]; then
    command eza -l .
  else
    command eza -l "$@"
  fi
}
if type compdef &>/dev/null; then
  compdef _eza ll 2>/dev/null
fi

# ===== Locale 设置 =====
# 使用推荐的最小集合，避免 LC_ALL 覆盖导致的异常
unset LC_ALL
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
# 使用 C 排序避免找不到本地化定义
export LC_COLLATE=C

# ===== zsh 性能优化设置 =====
# 禁用可能慢的 completion 功能
# compdef -d  # 清除所有 completion 定义

# 优化历史设置
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

# ===== 函数定义 =====
# zsh 的 cd - 功能已经内置，不需要额外函数

# mkcd 函数：创建目录并进入
mkcd() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: mkcd <directory>"
    return 1
  fi
  mkdir -p "$1" && cd "$1"
}

# rm 函数：使用 trash-cli 安全删除
rm() {
  if command -v trash-put &> /dev/null; then
    trash-put "$@"
  elif command -v trash &> /dev/null; then
    trash "$@"
  else
    echo "Error: 'trash' command not found. Please install 'trash-cli' to use safe deletion."
    return 1
  fi
}

# ===== 性能优化 =====
# 减少不必要的路径扫描
unset MAILCHECK  # 禁用邮件检查

# ===== 其他优化 =====
# 启用自动补全缓存
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# 补全样式
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors
zstyle ':completion:*' verbose yes
