# pre-commit 依赖工具集 —— 唯一手写清单（单一事实来源）。
#
# 为什么存在：
#   仓库里有两个消费端（CI devShell、本地 home-manager home.packages）都依赖
#   .pre-commit-config.yaml 里 `language: system` hooks 的二进制。若两处各自手写
#   包列表，加/换 linter 时要同步改多处，容易漂移。这里收口成一份清单，
#   `mylib.precommitTools { inherit pkgs; }` 返回要安装的包列表。
#
# 与 .pre-commit-config.yaml 的对应关系（entry 命令名 → 本清单包名）：
#   - 13 个 pre-commit 内置 hooks（end-of-file-fixer / check-* / trailing-whitespace-fixer
#     等）在 nixpkgs 没有独立包，统一由 python3Packages.pre-commit-hooks 提供二进制
#   - `language: golang` hooks（betteralign / nilaway / go-test）由 pre-commit 自行
#     `go install` 进隔离环境，**不需要**在这里提供 Go 工具链
#   - `tofu` 在 nixpkgs 的包名是 `opentofu`（二进制名才是 tofu）
#   - 其余与 pre-commit config 的 entry 同名
{ pkgs }:
with pkgs;
[
  actionlint
  caddy
  commitizen
  deadnix
  gitleaks
  golangci-lint
  hadolint
  markdownlint-cli
  opentofu
  pre-commit
  prettier
  python3Packages.pre-commit-hooks
  ruff
  shellcheck
  statix
  stylelint
  treefmt
  yamllint
]
