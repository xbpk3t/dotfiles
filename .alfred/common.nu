#!/usr/bin/env nu

# 共享的 Alfred / Nushell 辅助函数

# 确保 PATH 覆盖常见安装位置（Homebrew / Nix / 系统），避免 Alfred 环境过窄。
export def ensure-path [] {
  let merged = ([
    "/opt/homebrew/bin"
    "/usr/local/bin"
    "/run/current-system/sw/bin"
    "/usr/bin"
    "/bin"
    ($env.PATH? | default "")
  ]
  | where { |p| $p != "" }
  | str join ":")

  $env.PATH = $merged
}

# 生成 Alfred 错误输出（valid=false），避免回车后报错。
export def alfred-error [title: string, subtitle?: string] {
  { items: [ { title: $title, subtitle: ($subtitle | default ""), valid: false } ] } | to json -i 2
}

# 检查外部命令是否存在，不在则输出提示并退出 0。
export def ensure-cmd [name: string, hint: string] {
  let found = (which $name | default [])
  if ($found | is-empty) {
    alfred-error $"缺少命令: ($name)" $hint | print
    exit 0
  }

  $found.0.path
}

# 不存在则尝试安装（install_cmd 例如: `go install github.com/xbpk3t/docs-alfred/pwgen@main`）
export def ensure-cmd-or-install [name: string, install_cmd: string, ctx: string] {
  let found = (which $name | default [])
  if not ($found | is-empty) {
    return $found.0.path
  }

  # 需要 go install 时检查 go 是否存在
  if ($install_cmd | str contains "go install") and ((which go | default []) | is-empty) {
    alfred-error $"缺少命令: ($name)" "未找到 go，无法自动安装；请先安装 Go" | print
    exit 0
  }

  let install_res = (try {
    ^sh "-c" $install_cmd
    "ok"
  } catch {|err|
    let msg = ($err.msg? | default ($err | into string))
    alfred-error $"自动安装 ($name) 失败" $msg | print
    "fail"
  })

  if $install_res != "ok" {
    exit 0
  }

  let refound = (which $name | default [])
  if ($refound | is-empty) {
    alfred-error $"自动安装 ($name) 后仍未找到命令" $install_cmd | print
    exit 0
  }

  $refound.0.path
}

# 执行命令并包装错误为 Alfred 输出；返回 stdout 字符串。
export def run-safe [cmd_path: string, args: list<string>, ctx: string] {
  let result = (try {
    ^$cmd_path ...$args | complete
  } catch {|err|
    let msg = ($err.msg? | default ($err | into string))
    alfred-error $"($ctx) 执行失败" $msg | print
    exit 0
  })

  if ($result.exit_code != 0) {
    let msg = ($result.stderr | default $result.stdout | default "")
    alfred-error $"($ctx) 执行失败" ($msg | str trim) | print
    exit 0
  }

  $result.stdout | default "" | into string
}
