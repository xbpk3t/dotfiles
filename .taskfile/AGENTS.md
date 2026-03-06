---
name: Global .taskfile Agent Guide
purpose: Maintain global Taskfile repository used via symlink and `task -g`
audience: AI coding agents and automation tools
language: zh-CN
task_runner: go-task
scope:
  repo_root: ".taskfile"
  symlink_target: "$HOME/taskfile"
  invocation:
    global: "task -g <task>"
    debug: "task -t <taskfile-path> <task>"
priority:
  must:
    - stability
    - minimal-diff
    - idempotency
    - verifiability
  avoid:
    - cosmetic-refactor
    - mass-reorder
    - breaking-changes
entry_points:
  - ".taskfile/Taskfile.yml (root)"
verification:
  list:
    - "task -t <taskfile-path> --list"
    - "task -g --list"
  dry_run:
    - "task -t <taskfile-path> -n <task>"
    - "task -g -n <task>"
  run:
    - "task -t <taskfile-path> <task>"
    - "task -g <task>"
reporting:
  required_sections:
    - Changed files
    - Changed tasks
    - Verification commands
    - Risks & rollback
---




## 1) 执行模型（你必须理解的调用方式）

### 1.1 全局使用方式（最终用户路径）
- `.taskfile` 会通过 `home.file` symlink 到：`$HOME/taskfile`
- 用户通过 `task -g <task>` 调用全局任务

**含义：**
- 任何入口任务的变更都可能影响你所有机器/所有 shell 环境；
- 任务名、alias、输出格式被视为“稳定接口”。

### 1.2 调试方式（开发/排错路径）
- 调试时必须使用：`task -t <taskfile-path> <task>`
  - 例如：`task -t .taskfile/Taskfile.yml <task>`
  - 或指向某个被 includes 的子 taskfile（若需要单独验证）

---

## 2) 通用规则与流程

通用规则与流程已迁移到 skill：`taskfile-best-practices`（路径：`home/base/tui/ai/skills/taskfile-best-practices/SKILL.md`）。

本 AGENTS 仅保留本仓库的全局约束与接口稳定性要求。
