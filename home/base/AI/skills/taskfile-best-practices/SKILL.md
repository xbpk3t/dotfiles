---
name: taskfile-best-practices
description: Taskfile(go-task) 最佳实践与模式，适用于新增/修改 Taskfile.yml、设计任务结构、保证幂等与可维护性、使用 vars/status/preconditions/summary/wildcard 等特性。遇到 Taskfile 设计、重构或排错时使用。
trigger_keywords:
  - taskfile
  - go-task
  - Taskfile.yml
---

# Taskfile Best Practices

## 适用范围

- 仅提供通用 Taskfile 设计与实现建议
- 仓库级强约束（入口稳定、验证流程、输出格式等）以 AGENTS 为准

## Schema 说明

- 官方 schema：`https://taskfile.dev/schema.json` 如果需要使用某个key，请直接查看该 schema.json 是否支持
- 本地整理：`references/schema.yaml`

> 以官方 schema 为准；本地整理用于快速查阅与评估字段影响面。

## 修改前必做的定位步骤（MUST）

1) 找到入口任务（用户会调用的 task 名或 alias；root + includes 中**非 internal** 的任务）
2) 找到真实定义位置（root 或 includes 的子 Taskfile）
3) 识别任务类型（交互 / 有副作用 / 只读）

## Best Practices

- 单一事实源：`references/best-practices.yaml`
- 使用方式：
    - 先按三大核心分类（幂等性 / 可复用性 / 可维护性）定位规范
    - 每条规则包含 `level`（MUST / MUST_NOT / SHOULD），用于区分强约束与建议
    - 修改/评审任务时，以 MUST/MUST_NOT 为硬约束，SHOULD 为优化建议
- YAML schema 说明：
    - `best_practices[]`：最佳实践分类列表
    - `category`：英文分类标识（idempotency / reusability / maintainability）
    - `title`：中文分类名
    - `qs`：该分类的引导问题
    - `items[]`：规则列表
    - `items[].id`：英文规则标识
    - `items[].name`：中文规则名
    - `items[].level`：规则级别（MUST / MUST_NOT / SHOULD）
    - `items[].text`：规则描述与执行要点

## 修改流程（MUST，按顺序执行）

1) 定位：入口 → includes 链路 → 真实定义
2) 修改：最小 diff，避免高风险改动
3) 验证：先局部（task -t）再全局（task -g），必要时幂等任务跑两次
4) 汇报：Changed files / Changed tasks / Verification commands / Risks & rollback

## gotchas（MUST 避免）

- 单一事实源：`references/gotchas.yaml`
- 使用方式：
    - 变更前先对照 gotchas 列表，避免引入已知误区
    - 如出现问题，优先匹配 desc + fix 的修复建议
- YAML schema 说明：
    - `gotchas[]`：问题清单
    - `id`：英文问题标识
    - `title`：中文问题名
    - `desc`：问题描述
    - `fix`：修复建议

## 常见关键字用途

- `requires`: 声明任务所必需的变量（变量未设置则任务失败），适用于基础的存在性校验。
- `preconditions`: 在任务运行前执行校验命令，可对输入参数进行值范围、格式等业务逻辑校验。通常作为输入参数校验的主要关键字。
- `vars`: 定义任务的局部变量。
- `status`: 定义检查命令，判断任务是否已是最新状态（用于幂等控制）。
- `summary`: 为任务提供简短描述。
- `wildcard`: 用于通配符任务名，实现批量任务定义。

> 对于"输入参数校验"场景，首选 `preconditions` 实现自定义校验逻辑，仅需确保变量存在时可选用 `requires`。

## 关键字段区分

这三个字段容易混淆，明确职责边界：

- `requires` — 声明任务所需的变量（变量缺失则报错），仅做存在性校验，不做值范围/格式校验
- `preconditions` — 在任务执行前运行校验命令，可对输入做值范围、格式等业务逻辑校验
- `status` — 定义幂等检查命令，判断任务是否已是最新状态（如文件已存在、内容一致则跳过）

> 一句话记：**requires 检查"有没有"、preconditions 检查"对不对"、status 检查"做没做"**。

## vars:sh 约束

`vars:` 中使用 `sh` 子命令时，必须遵守以下规则：

- **禁止任何副作用**：不得写入文件、发起网络请求、修改外部状态
- **必须是纯计算表达式**：仅用于派生变量值（如格式化路径、读取文件内容）
- **幂等性**：多次执行必须返回相同结果

## 入口任务规范（MUST）

所有面向用户的入口任务必须同时定义：

- `desc` — 简短摘要（一行）
- `summary` — 详细使用说明（多行，含参数和注意事项）
