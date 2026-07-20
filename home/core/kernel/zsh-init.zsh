# shellcheck shell=bash
# 交互式 zsh 片段：HM 无对应一等 option 的 zstyle / 函数放这里。
# 纯 env / alias / setopt / 插件顺序见 zsh.nix；worktrunk 见 devops/git.nix。

# ===== 补全 zstyle（与 use-cache 配合；compinit 前后均可设）=====
# 不区分大小写的制表符补全
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|=*' 'l:|=* r:|=*'

# 补全缓存（需目录存在）
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${HOME}/.zsh/cache"

# Tab 菜单选择
zstyle ':completion:*' menu select

# ===== 函数 =====
# mkcd：创建目录并进入（纯 alias 无法带参 mkdir+cd；md=mkdir -p 见 zsh.nix）
mkcd() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: mkcd <directory>"
    return 1
  fi
  mkdir -p "$1" && cd "$1" || return
}
