---
name: taskfile-best-practices
description: Taskfile(go-task) 最佳实践与模式，适用于新增/修改 Taskfile.yml、设计任务结构、保证幂等与可维护性、使用 vars/status/preconditions/summary/wildcard 等特性。遇到 Taskfile 设计、重构或排错时使用。
---

# Taskfile Best Practices

## 适用范围

- 仅提供通用 Taskfile 设计与实现建议
- 仓库级强约束（入口稳定、验证流程、输出格式等）以 AGENTS 为准

## 修改前必做的定位步骤（MUST）

1) 找到入口任务（用户会调用的 task 名或 alias）
2) 找到真实定义位置（root 或 includes 的子 Taskfile）
3) 识别任务类型（交互 / 有副作用 / 只读）

## 硬性规则（MUST / MUST NOT）

### 格式与结构

- MUST 保留原有注释、空行分组、任务顺序、key 顺序（除非变更需要）
- MUST NOT 批量格式化 YAML、排序字段、重排任务（仅为统一风格）

### 幂等与校验

- 有副作用的任务：尽量提供 status（仅决定是否执行，不掩盖错误）
- 必要输入使用 preconditions 进行校验

### 动态变量（vars: sh）

- MUST 输出稳定、可预测
- MUST 失败可诊断（错误信息明确）
- MUST NOT 在 vars: sh 中做复杂流程或副作用（写文件/改系统状态）

### 交互与静默

- 用户入口任务必须有 desc
- 交互任务应明确标记 interactive: true（如仓库已有惯例）
- MUST NOT 随意改 silent 导致日志/解析变更

### summary 与 usage

- 用户入口任务必须提供 summary，写明全局调用方式
- summary 中用 [] 标注可选参数；必填参数放入 requires 并同步到 summary

## 修改流程（MUST，按顺序执行）

1) 定位：入口 → includes 链路 → 真实定义
2) 修改：最小 diff，避免高风险改动
3) 验证：先局部（task -t）再全局（task -g），必要时幂等任务跑两次
4) 汇报：Changed files / Changed tasks / Verification commands / Risks & rollback

## 常见坑（MUST 避免）

- 把 deps 当成“复用代码”乱加，导致顺序/副作用边界改变
- status 只检查“文件存在”不检查正确性，导致永远跳过
- 修改 silent / 输出文本导致脚本或 alias 解析失败
- 把复杂逻辑塞进 vars: sh，导致不可维护/不可诊断
- 只在 task -t 通过但没验证 task -g

## 设计与复用

- 优先复用既有模板 task；多处复用的值定义为 vars
- 入口多的项目拆分多个 Taskfile.yml，再在根 Taskfile includes
- 使用 wildcard 参数收敛同构任务（如 svc:* 这一类）

## 幂等与安全

- 有副作用的任务尽量提供 status（只决定是否执行，不掩盖错误）
- 关键输入使用 preconditions 做校验
- vars: sh 仅用于稳定、可预测、无副作用的动态值

## 参数与文档

- 入口任务应提供 summary，写明全局调用方式
- 可选参数在 summary 中用 [] 标注，必填参数放入 requires 并同步到 summary

## Shell 约束

- 在 task 里使用 set: [pipefail]，不要在 cmd 中手写 set -euo pipefail
- 复杂流程避免塞进 vars: sh，保持可诊断性
