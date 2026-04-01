# CLI_ARGS 复核清单（待逐项处理）

- 说明：以下任务使用 {{.CLI_ARGS}}，但实际属于多参数或多语义场景，建议后续逐项改为显式 vars。

- `
- `.taskfile/mac/Taskfile.markdown.yml` / `md2html`: gm 常见多参数（flags + file）
- `.taskfile/mac/Taskfile.trzsz.yml` / `upload`: trz 选项组合，多参数
- `.taskfile/mac/Taskfile.trzsz.yml` / `download`: tsz 选项组合，多参数
- `.taskfile/mac/Taskfile.me.yml` / `cv`: rendercv render 常见多参数
- `.taskfile/nix/Taskfile.test.yml` / `syntax-verify`: nix-instantiate 可带多参数/多文件
- `.taskfile/k8s/Taskfile.helm.yml` / `<vars>`: RELEASE_NAME/CHART_NAME/REPO_NAME/REPO_URL 绑定 CLI_ARGS，语义冲突
