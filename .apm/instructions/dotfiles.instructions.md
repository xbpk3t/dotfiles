---
description: Dotfiles project rules for NixOS/nix-darwin/home-manager fleet management
applyTo: "**"
---
# Dotfiles Project Rules

## 项目概览

NixOS/nix-darwin/home-manager 的 flake-parts 项目，管理多平台（macOS、NixOS、WSL、AVF/Android）的 fleet 配置。flake-parts 做模块化编排，deploy-rs 统一部署，sops-nix 管理密钥。

## 关键命令

所有操作入口为 go-task（`task`）：

```bash
# 部署
task nix:deploy            # 交互式多选节点部署（deploy-rs，--impure）
task nix:rollback          # 回滚当前机器到上一代配置

# Flake 维护
task nix:flake:update      # 更新所有 flake inputs (nix flake update)
task nix:flake:rm          # 移除 flake 包后的清理流程（lock → check → metadata）
task nix:test:quick        # 快速验证当前 host 配置 (targeted nix eval)

# SOPS 密钥
task nix:sk:edit           # 编辑加密的 secrets 文件
task nix:sk:view           # 查看 & 验证解密后的 secrets 内容
task nix:sk:k8s:edit       # 编辑 k8s SOPS 加密的 manifest
task nix:sk:k8s:view       # 查看解密后的 k8s manifest

# Terraform/OpenTofu
task tf:plan               # Terraform plan
task tf:apply              # Terraform apply
task tf:validate           # Terraform validate
```


## 架构与重要决策

### Flake 单通道 rolling branch

所有 inputs 统一跟随 `nixpkgs-unstable`（或对应 master），不保留 stable/unstable 双通道。原因：dotfiles 偏向持续滚动升级，双通道是虚假抽象，统一通道降低维护成本。

### 分层结构

```
hosts/<name>/          # 每台机器的 identity：default.nix (系统) + home.nix (用户)
home/base/             # 跨平台共享的用户 app 配置 (AI/desktop/langs/ms/works 等)
home/core/             # 更底层/通用的用户配置 (devops/infra)
home/darwin/           # macOS 专属 home-manager 配置
home/nixos/            # NixOS 专属 home-manager 配置
home/extra/            # 额外/实验性 home-manager 配置
modules/nixos/base/    # 能力型系统模块，只定义 options 和实现
modules/nixos/<role>/  # 角色型模块 (apps/desktop/homelab/laptop/vps/extra/hardware)
modules/darwin/        # nix-darwin 系统模块
lib/                   # Nix helper 函数库
pkgs/                  # 自定义 nix 包
outputs/               # flake-parts outputs 子模块
```

### home/base vs home/core 的分层原因

- `home/base/`：按功能分类的大类 app 配置（AI、desktop、langs、ms、works 等），跨平台共享
- `home/core/`：更核心/通用的配置，如 devops 和 infra 基础工具，也是跨平台但更偏底层

### deploy-rs 统一部署

从 colmena 迁移到 deploy-rs，原因：colmena 不支持 multi-profile（Darwin 和 NixOS 需要不同部署工具），deploy-rs 统一了所有 profile 的部署流程。部署使用 `--impure` 评估以兼容当前 working tree（仓库内存在未 track 的源码目录时 pure evaluation 会失败）。

### 密钥管理

- **sops-nix**：系统/用户级密钥（age key），配置文件在 `secrets/`
- **SOPS**：Kubernetes secrets（`manifests/**/*.sops.yaml`），仅加密 `data`/`stringData` 保留结构可读
- `.sops.yaml` 定义加密规则，按路径正则分流

## 代码规范与约定

### Nix 格式化

统一使用 alejandra 或 nixfmt 格式化。保持一致性，不要在同一文件中混用风格。

### 模块设计原则

- `modules/nixos/base` 中的能力型模块只定义 options 和实现本身，不要在角色包装中加 `enable = true`
- 角色是否启用某能力，直接在 `hosts/<name>/default.nix` 中声明；自定义参数也直接在 host 层处理
- 遇到容易与上游 NixOS 选项混淆的模块名时，命名要体现语义边界（如区分 systemd watchdog 与 `services.watchdogd`）

### 目录约定

- `hosts/<name>/`：每台机器的 identity，包含 `default.nix`（系统配置）和 `home.nix`（用户配置）
- `pkgs/`：存放自己打包的 nix package
- `compound/`：沉淀已解决问题和可复用实践（不在本仓库，在 docs monorepo 侧）
- `docs/` 中的文档只读，不随意修改

### 通用约定

- 优先使用 `lib.mkDefault` 让值可被覆盖
- 跨平台配置放 `home/base/`，平台特有放 `home/darwin/` 或 `home/nixos/`
- 修改 flake input 后运行 `nix flake lock` 并检查 `flake.lock` 变更

## 工作流与流程

### 部署前检查

1. `task nix:test:quick` — 确保当前 host 配置评估通过（日常）；`nix flake check` 用于 CI/全量验证
2. 确认 `flake.lock` 已提交（避免部署未锁定的版本）
3. `task nix:deploy` — 交互式选择目标节点，deploy-rs 会跳过内建 checks 并用 `--impure` 评估

### 测试策略

- `task nix:test:quick` 验证当前 host 的 module evaluation（仅评估，不触发构建/下载）
- `nix flake check`（不加 `--no-build`）用于 CI 或提交前的全量 fleet 验证
- `tests/` 目录包含 nix-unit 测试

### 回滚

`task nix:rollback` 自动检测平台（Darwin → `darwin-rebuild --rollback`，Linux → `nixos-cli rollback`）。

## Claude 行为守则

1. **先读 flake.nix**：任何涉及 Nix 配置的修改，先理解 `flake.nix` 的 inputs/outputs 结构
2. **保守改动**：Nix 改动影响面广（可能影响多台机器），修改模块时考虑跨平台兼容性
3. **不自动部署**：绝对不要在未经用户明确确认的情况下执行 `task nix:deploy` 或任何部署命令
4. **不修改 docs/ 内容**：`docs/` 中的文档由 docs monorepo 管理，dotfiles 侧只读
5. **修改配置后运行检查**：改完 `.nix` 文件后至少执行 `task nix:test:quick` 确保当前 host 配置评估通过
6. **不自动 commit/push**：等待用户确认后再提交
7. **Linear 驱动开发**：开始任务前先检查是否有对应 Linear issue；较大任务先创建 issue 再开工。
8. **issue 状态管理**：开始 → In Progress，阻塞 → comment 说明，完成 → Done + 总结。
9. **分支命名**：`luc-{ISSUE_KEY}-{short-slug}`，PR 标题和 body 包含 issue key 触发自动关联。

## 其他提醒

- **SOPS 安全**：`secrets/` 和 `manifests/**/*.sops.yaml` 包含加密密钥，永远不要尝试解密后明文提交。检查 diff 时确认只有密文变更
- **Impure 评估**：部署和部分 eval 命令需要 `--impure`，因为仓库中存在未 track 的源码目录会阻断 pure flake evaluation。这是有意为之，不要尝试"修复"
- **跨平台注意**：macOS 用 `nix-darwin`，Linux 用 NixOS，WSL 用 `nixos-wsl`，AVF 用 `nixos-avf`。同一份 home-manager 配置在不同平台上可能有不同的可用包集合
- **`hosts/<name>/` 是机器的 identity**：新增机器时在这里创建目录，包含 `default.nix`（系统级）和 `home.nix`（用户级），然后在 flake outputs 中注册
- **flake.lock 是部署的关键契约**：它锁定了所有 inputs 的版本，部署到任何机器都使用同一份 lock，保证 fleet 一致性
