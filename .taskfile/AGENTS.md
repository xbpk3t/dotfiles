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

## 2) 修改前必做的定位步骤（MUST）

1) 找到入口任务：
- 用户会用 `task -g ...` 直接调用的任务名或 `alias`

2) 找到真实定义位置：
- 入口任务可能在 root，也可能来自 `includes` 引入的子 Taskfile

3) 识别任务类型：
- 交互（interactive/gum）
- 有副作用（生成文件/构建/安装/改系统状态）
- 纯查询/只读

---

## 3) 硬性规则（MUST / MUST NOT）

### 3.1 格式与结构
- **MUST** 保留原有注释、空行分组、任务顺序、key 顺序（除非变更需要）。
- **MUST NOT** 批量格式化 YAML、排序字段、重排任务，只为“统一风格”。

### 3.2 兼容性与入口稳定（全局 API）
- **MUST NOT** 随意重命名任务名或修改 `alias`。
- **MUST NOT** 修改既有任务的输出格式/前缀（尤其会被脚本/alias/grep 解析的输出）。
- 若必须改动上述内容（仅在明确要求时）：
  - **MUST** 同步更新所有引用点（其它任务、文档、shell alias、脚本）
  - **MUST** 在最终汇报中列出影响范围与回滚方法

### 3.3 幂等（Idempotency）
- 对“会产生产物/副作用”的任务：
  - **MUST** 尽量提供 `status`（避免重复执行）
  - **MUST** 用 `preconditions` 做输入/环境校验
- **MUST NOT** 用 `status` 掩盖真实错误（status 只决定“要不要跑”，不决定“错不错”）

### 3.4 动态变量（vars: sh）
- 允许使用 `vars: { X: { sh: ... } }`，但：
  - **MUST** 输出稳定、可预测（同环境同输入得到稳定输出）
  - **MUST** 失败可诊断（错误信息明确）
  - **MUST NOT** 在动态变量里做复杂流程/有副作用动作（写文件、改系统状态等）

### 3.5 交互与静默（interactive / silent）
- 用户入口任务：
  - **MUST** 有 `desc`
- 交互任务：
  - **MUST** 明确标记 `interactive: true`（如仓库已有此惯例）
  - **MUST** 考虑非交互环境行为：清晰失败或可控降级
- **MUST NOT** 因为“更安静”而随意改 `silent` 导致日志/解析变更

### 3.6 summary 与 usage（新增）
- **MUST** 为用户入口任务补充 `summary`，用于写明全局调用方式（`task -g ...`）。
- **MUST** 在 `summary` 中用 `[]` 标注可选参数（例如 `SVC` 可选则写 `SVC=[sshd]`）。
- **MUST** 若某个参数是必填，则必须写在 `requires` 中，并同步在 `summary` 中体现。

---

## 4) 最佳实践（Best practices）


```yaml


- 用 {{.CLI_ARGS}} 可以 透传命令行参数 # 注意使用场景：仅限于单参数情况下，直接透传。如果是多参数，更应该使用vars传递
- 多定义 vars # 正如写golang代码，多定义const，增加可维护性
- 拆分多个 Taskfile.yml # 如果有多入口的项目，应该给每个入口各自一个Taskfile.yml（具体来说就是，在该pkg内是主Taskfile，再统一includes到项目根目录，统一调用）
- "动态变量/增强变量 `Vars: sh: <shell>`"

- "***【复用性】1、直接复用【模板task】。2、多定义vars（正如写golang代码，多定义const，增加可维护性）***" # https://task-zh.readthedocs.io/zh-cn/latest/usage.zh/#_13
- "***【幂等性】怎么保证task的幂等性？***"
- 【隔离性】1、拆分多个Taskfile.yml（如果有多入口的项目，应该给每个入口各自一个Taskfile.yml（具体来说就是，在该pkg内是主Taskfile，再统一includes到项目根目录，统一调用））
- "***【模板task】怎么复用 模板task?***"

- 【Wildcard参数】用通配符简化同构命令（类似 svc:* 这种写法） # 比如说 systemctl <ACTION> <UNIT> 其中 ACTION都是同构的，就没必要写到多个task里面，可以用通配符都收束到一个task里 # https://taskfile.dev/docs/guide#wildcard-arguments

- 【限制执行】用 platform + if + preconditions 来做限制执行，
- 【vars约束】用 requires 验证vars是否存在
- 【vars】只要是多处调用的，就需要定义为task的vars。如果多个task都复用了部分vars，那么就需要把这些vars放到taskfile级别。

- "【set】在task里写明 `set: [pipefail]`，不要在task的cmd里面写 set -euo pipefail" # https://taskfile.dev/docs/reference/schema#set
```




---

## 5) 修改流程（MUST，按顺序执行）

1) **定位**：入口 → includes 链路 → 真实定义
2) **修改**：最小 diff；避免高风险改动
3) **调试验证（优先 task -t）**：
   - `task -t <taskfile-path> --list`
   - `task -t <taskfile-path> -n <affected-task>`（如支持）
   - `task -t <taskfile-path> <affected-task>`（必要时；幂等任务建议连续跑两次）
4) **全局路径验证（task -g）**：
   - `task -g --list`
   - `task -g -n <affected-task>`（如支持）
   - `task -g <affected-task>`
5) **汇报（最终回复必须包含）**：
   - Changed files
   - Changed tasks（入口/内部、alias 是否变化）
   - Verification commands（分别列 task -t 与 task -g）
   - Risks & rollback

---

## 6) 常见坑（MUST 避免）

- 把 `deps` 当成“复用代码”乱加，导致顺序/副作用边界改变。
- `status` 只检查“文件存在”，不检查新旧/正确性，导致永远跳过。
- 修改 `silent` / 输出文本导致脚本或 alias 解析失败。
- 把复杂逻辑塞进 `vars: sh`，让任务不可维护/不可诊断。
- 只在 `task -t` 通过但没验证 `task -g`（全局 symlink 路径可能存在差异）。
