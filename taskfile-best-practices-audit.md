# Taskfile 最佳实践检查报告 (.taskfile)

- 日期: 2026-03-06
- 扫描范围: .taskfile/**/Taskfile*.yml（共 109 个文件）
- 规则来源: taskfile-best-practices/references/best-practices.yaml + gotchas.yaml
- 方法: 静态扫描（不执行任务）
- 假设: 所有 includes 里的任务都可能作为入口任务被 `task -g` 调用，因此要求具备 desc 与 summary

## 确定不符合 (MUST / MUST_NOT)

### 入口任务缺少 desc/summary (MUST)

- `.taskfile/devops/Taskfile.linters.yml` / `scan-project`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `process-configs`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `process-single-linter`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `process-single-config`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `list`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `list-dotfiles`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `validate-dotfiles`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `validate-project`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `process-single-files`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `process-single-file`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.linters.yml` / `validate-single-files`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.rclone.yml` / `sync`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.rclone.yml` / `bisync`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.rclone.yml` / `check`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.rclone.yml` / `rev-sync`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.rclone.yml` / `delete`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.rclone.yml` / `purge`: 缺少 desc 或 summary
- `.taskfile/devops/Taskfile.rclone.yml` / `rmdirs`: 缺少 desc 或 summary
- `.taskfile/k8s/Taskfile.helm.yml` / `_validate-release-params`: 缺少 desc 或 summary
- `.taskfile/k8s/Taskfile.helm.yml` / `_validate-helmfile`: 缺少 desc 或 summary
- `.taskfile/k8s/Taskfile.helm.yml` / `_validate-cr-params`: 缺少 desc 或 summary
- `.taskfile/kernel/Taskfile.linux.yml` / `kp:linux`: 缺少 desc 或 summary
- `.taskfile/kernel/Taskfile.linux.yml` / `kp:darwin`: 缺少 desc 或 summary
- `.taskfile/kernel/Taskfile.pkg.yml` / `execute`: 缺少 desc 或 summary
- `.taskfile/kernel/Taskfile.power.yml` / `_check:systemd`: 缺少 desc 或 summary
- `.taskfile/kernel/Taskfile.user.yml` / `_call`: 缺少 desc 或 summary
- `.taskfile/mac/Taskfile.brew.yml` / `_upgrade`: 缺少 desc 或 summary
- `.taskfile/mac/Taskfile.brew.yml` / `_info`: 缺少 desc 或 summary
- `.taskfile/mac/Taskfile.brew.yml` / `_cleanup`: 缺少 desc 或 summary
- `.taskfile/mac/Taskfile.scratches.yml` / `_nb:ensure`: 缺少 desc 或 summary
- `.taskfile/mac/Taskfile.scratches.yml` / `_nb:ensure_picker`: 缺少 desc 或 summary
- `.taskfile/network/Taskfile.chrony.yml` / `_check`: 缺少 desc 或 summary
- `.taskfile/network/dns/Taskfile.dig.yml` / `_dig`: 缺少 desc 或 summary
- `.taskfile/nix/Taskfile.flake.yml` / `check-config`: 缺少 desc 或 summary
- `.taskfile/nix/Taskfile.nixos-anywhere.yml` / `_check_local`: 缺少 desc 或 summary
- `.taskfile/nix/Taskfile.nixos-anywhere.yml` / `_check_remote`: 缺少 desc 或 summary
- `.taskfile/nix/Taskfile.nixos-anywhere.yml` / `_ssh_assert`: 缺少 desc 或 summary
- `.taskfile/nix/Taskfile.nixos-anywhere.yml` / `_run`: 缺少 desc 或 summary
- `.taskfile/works/AI/Taskfile.skills.yml` / `suggest`: 缺少 desc 或 summary

### cmd 中手写 set -euo pipefail (MUST_NOT)

- `.taskfile/mac/Taskfile.mac.yml` / `svc:*`: cmd 中出现 set -euo pipefail
- `.taskfile/mac/Taskfile.mac.yml` / `status:*`: cmd 中出现 set -euo pipefail
- `.taskfile/mac/Taskfile.mac.yml` / `logs:*`: cmd 中出现 set -euo pipefail
- `.taskfile/mac/Taskfile.mac.yml` / `reload`: cmd 中出现 set -euo pipefail
- `.taskfile/nix/Taskfile.sops.k8s.yml` / `k8s:generate`: cmd 中出现 set -euo pipefail

### vars: sh 存在副作用嫌疑 (MUST_NOT)

- `.taskfile/nix/Taskfile.flake.yml` / `why`: vars.KIND.sh 疑似副作用: d="$(nix eval --raw .#darwinConfigurations --apply "x: builtins.toString (builtins.length (builtins.attrNames x))" 2>/dev/null || echo 0)"; n="$(nix eval --raw .#nixosConfigurations --apply "x: builtins.toString (builtins.length (builtins.attrNames x))" 2>/dev/null || echo 0)"; { [ "$d" != "0" ] && echo darwin; [ "$n" != "0" ] && echo nixos; } | gum choose --header "选择配置类型"
- `.taskfile/nix/Taskfile.flake.yml` / `why`: vars.HOST.sh 疑似副作用: nix eval --raw ".#{{.KIND}}Configurations" --apply "x: builtins.concatStringsSep \\\"\\n\\\" (builtins.attrNames x)" | gum choose --header "选择 Host"
- `.taskfile/nix/Taskfile.flake.yml` / `why`: vars.SYSTEM_DRV.sh 疑似副作用: test "{{.KIND}}" = "darwin" && nix eval --raw ".#darwinConfigurations.{{.HOST}}.system.drvPath" || nix eval --raw ".#nixosConfigurations.{{.HOST}}.config.system.build.toplevel.drvPath"
- `.taskfile/nix/Taskfile.nixos-anywhere.yml` / `_run`: vars.NA_BIN.sh 疑似副作用: command -v nixos-anywhere && echo nixos-anywhere || echo "nix run --refresh github:nix-community/nixos-anywhere --"

## 需确认 / 建议复核

### 使用 {{.CLI_ARGS}} 需确认是否单参数 (MUST)

- `.taskfile/devops/Taskfile.ansible.yml` / `ping`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/devops/Taskfile.git.yml` / `undo`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/devops/Taskfile.git.yml` / `fetch`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/devops/Taskfile.git.yml` / `modify-origin`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/devops/Taskfile.pre-commit.yml` / `init-template`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/devops/Taskfile.pre-commit.yml` / `try-repo`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/k8s/Taskfile.docker.yml` / `check-mem`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/k8s/Taskfile.docker.yml` / `check-cpu`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/mac/Taskfile.markdown.yml` / `md2html`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/mac/Taskfile.me.yml` / `cv`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/mac/Taskfile.trzsz.yml` / `upload`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/mac/Taskfile.trzsz.yml` / `download`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `ping-scan`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `arp-scan`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `no-ping`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `syn-scan`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `tcp-scan`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `udp-scan`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `port-range`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `version-detect`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `os-detect`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `aggressive`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `default-script`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `vuln-scan`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `ssl-cert`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `output-normal`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `output-xml`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `fast-scan`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `fragment`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `decoy`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `source-port`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/network/scan/Taskfile.nmap.yml` / `quick-web-scan`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景
- `.taskfile/nix/Taskfile.test.yml` / `syntax-verify`: 使用了 {{.CLI_ARGS}}，需确认是否单参数场景

### vars: sh 逻辑复杂，建议移到 cmds (MUST_NOT)

- `.taskfile/devops/Taskfile.git.yml` / `gist:clear`: vars.GIST_LIST.sh 逻辑较复杂，建议移到 cmds: gh gist list --limit 100 | awk '{print $1}'
- `.taskfile/devops/Taskfile.git.yml` / `<vars>`: vars.COMMIT_HASH.sh 逻辑较复杂，建议移到 cmds: if [ -d .git ] || git rev-parse --git-dir > /dev/null 2>&1; then
  git rev-parse HEAD
else
  echo ""
fi
- `.taskfile/devops/Taskfile.linters.yml` / `validate-dotfiles`: vars.DOTFILES_FILES.sh 逻辑较复杂，建议移到 cmds: ls -A "{{.DOTFILES_LINTERS}}" 2>/dev/null | grep -v '^\.\.$' | grep -v '^\.$' | tr '\n' ' ' | sed 's/[[:space:]]*$//' || echo ""
- `.taskfile/devops/Taskfile.linters.yml` / `validate-project`: vars.PROJECT_FILES.sh 逻辑较复杂，建议移到 cmds: if [ -d "{{.PROJECT_DIR}}/.github/linters" ]; then
  ls -A "{{.PROJECT_DIR}}/.github/linters" 2>/dev/null | grep -v '^\.\.$' | grep -v '^\.$' | tr '\n' ' ' | sed 's/[[:space:]]*$//' || echo ""
else
  echo ""
fi
- `.taskfile/devops/Taskfile.linters.yml` / `<vars>`: vars.LINTERS_TO_PROCESS.sh 逻辑较复杂，建议移到 cmds: # 获取dotfiles中的linter文件（包含隐藏文件）
DOTFILES_FILES=""
DOTFILES_DIR="$HOME/Desktop/dotfiles/.github/linters"
if [ -d "$DOTFILES_DIR" ]; then
  DOTFILES_FILES=$(ls -A "$DOTFILES_DIR" 2>/dev/null | grep -v '^\.\.\$' | grep -v '^\.\$' | tr '\n' ' ')
fi

# 获取项目中的linter文件（包含隐藏文件）
PROJECT_FILES=""
if [ -d "{{.PROJECT_DIR}}/.github/linters" ]; then
  PROJECT_FILES=$(ls -A "{{.PROJECT_DIR}}/.github/linters" 2>/dev/null | grep -v '^\.\.\$' | grep -v '^\.\$' | tr '\n' ' ')
fi

# 计算交集：只有当项目中存在且dotfiles中也有对应配置时才处理
LINTERS_TO_PROCESS=""
for proj_file in $PROJECT_FILES; do
  for dot_file in $DOTFILES_FILES; do
    if [ "$proj_file" = "$dot_file" ]; then
      LINTERS_TO_PROCESS="$LINTERS_TO_PROCESS $proj_file"
      break
    fi
  done
done

echo "$LINTERS_TO_PROCESS" | tr ' ' '\n' | grep -v '^$' | tr '\n' ' ' | sed 's/[[:space:]]*$//'
- `.taskfile/devops/Taskfile.linters.yml` / `<vars>`: vars.SINGLE_FILES_TO_PROCESS.sh 逻辑较复杂，建议移到 cmds: SINGLE_FILES=""
DOTFILES_ROOT="$HOME/Desktop/dotfiles"

# 从配置列表中检查每个文件
for file in {{.SYNC_FILES_CONFIG | join " "}}; do
  if [ -f "$DOTFILES_ROOT/$file" ]; then
    if [ -f "{{.PROJECT_DIR}}/$file" ]; then
      SINGLE_FILES="$SINGLE_FILES $file"
    fi
  fi
done

echo "$SINGLE_FILES" | tr ' ' '\n' | grep -v '^$' | tr '\n' ' ' | sed 's/[[:space:]]*$//'
- `.taskfile/devops/Taskfile.pre-commit.yml` / `hook`: vars.SELECTED.sh 逻辑较复杂，建议移到 cmds: gum choose {{.HOOKS | join " "}}
- `.taskfile/kernel/Taskfile.linux.yml` / `rename`: vars.PATTERN.sh 逻辑较复杂，建议移到 cmds: echo "{{.CLI_ARGS | default 'file renamed'}}" | awk '{print $1}'
- `.taskfile/kernel/Taskfile.linux.yml` / `rename`: vars.REPLACEMENT.sh 逻辑较复杂，建议移到 cmds: echo "{{.CLI_ARGS | default 'file renamed'}}" | awk '{print $2}'
- `.taskfile/kernel/Taskfile.linux.yml` / `rename`: vars.RECURSIVE.sh 逻辑较复杂，建议移到 cmds: echo "{{.CLI_ARGS}}" | grep -w -- "--recursive" > /dev/null && echo "true" || echo "false"
- `.taskfile/kernel/Taskfile.pkg.yml` / `<vars>`: vars.DISTRO.sh 逻辑较复杂，建议移到 cmds: if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo $ID
elif command -v lsb_release >/dev/null 2>&1; then
  lsb_release -i | cut -f2
else
  uname -s
fi
- `.taskfile/kernel/Taskfile.shell.yml` / `change`: vars.SELECTED.sh 逻辑较复杂，建议移到 cmds: gum choose {{.SHELLS | splitLines | join " "}}
- `.taskfile/network/Taskfile.z.yml` / `wake:diag`: vars.WIFI_DEV.sh 逻辑较复杂，建议移到 cmds: networksetup -listallhardwareports | awk '
$0 ~ /Hardware Port: (Wi-Fi|AirPort)/{getline; if ($1=="Device:") {print $2; exit}}
'
- `.taskfile/network/tcp/Taskfile.ss.yml` / `state:count`: vars.COUNT.sh 逻辑较复杂，建议移到 cmds: ss -tan "state {{.STATE}}" | sed '1d' | wc -l
- `.taskfile/network/tcp/Taskfile.ss.yml` / `timewait:count`: vars.COUNT.sh 逻辑较复杂，建议移到 cmds: ss -tan "state TIME-WAIT" | sed '1d' | wc -l
- `.taskfile/network/tcp/Taskfile.ss.yml` / `closewait:count`: vars.COUNT.sh 逻辑较复杂，建议移到 cmds: ss -tan "state CLOSE-WAIT" | sed '1d' | wc -l
- `.taskfile/network/tcp/Taskfile.ss.yml` / `fzf:tcp`: vars.LINE.sh 逻辑较复杂，建议移到 cmds: ss -tanp | sed '1d' | fzf --header='Pick a TCP connection (ss -tanp)' || true
- `.taskfile/network/tcp/Taskfile.ss.yml` / `fzf:tcp`: vars.SRC.sh 逻辑较复杂，建议移到 cmds: echo "{{.LINE}}" | awk '{print $4}'
- `.taskfile/network/tcp/Taskfile.ss.yml` / `fzf:tcp`: vars.DST.sh 逻辑较复杂，建议移到 cmds: echo "{{.LINE}}" | awk '{print $5}'
- `.taskfile/nix/Taskfile.deploy.yml` / `default`: vars.HOSTS.sh 逻辑较复杂，建议移到 cmds: {{.NODES_CMD}} | gum choose --no-limit --header "选择节点（可多选）"
- `.taskfile/nix/Taskfile.deploy.yml` / `profile`: vars.HOST.sh 逻辑较复杂，建议移到 cmds: {{.NODES_CMD}} | gum choose --header "选择节点"
- `.taskfile/nix/Taskfile.sops.k8s.yml` / `<vars>`: vars.AGE_KEY_FILE.sh 逻辑较复杂，建议移到 cmds: if [ -n "${AGE_KEY_FILE:-}" ]; then
  printf "%s" "$AGE_KEY_FILE"
elif [ -f "$HOME/Library/Application Support/sops/age/keys.txt" ]; then
  printf "%s" "$HOME/Library/Application Support/sops/age/keys.txt"
elif [ -f "$HOME/.config/sops/age/keys.txt" ]; then
  printf "%s" "$HOME/.config/sops/age/keys.txt"
else
  printf "%s" "{{.USER_WORKING_DIR}}/age.key"
fi
- `.taskfile/works/AI/Taskfile.skills.yml` / `info`: vars.REPO.sh 逻辑较复杂，建议移到 cmds: repos="{{range .SKILLS}}{{.repo}}\n{{end}}"; if [ -z "$repos" ]; then exit 0; fi; printf "%b" "$repos" | gum choose --header "选择 skills repo"

