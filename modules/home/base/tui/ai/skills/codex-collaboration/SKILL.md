---
name: codex-collaboration
description: 管理与Codex的协作流程，包括深度分析、复杂逻辑设计、代码审查等。当任务需要深度推理、>10行核心逻辑设计或质量审查时使用。
---

# Codex Collaboration Skill

## 🚀 功能概述

本 skill 封装了与 Codex 协作的完整流程和规范，让主AI能够：

- 进行深度分析和复杂推理
- 设计复杂逻辑（>10行核心逻辑）
- 执行代码质量审查和风险评估
- 收集和管理上下文信息
- 自动化执行协作流程

## 🤝 审查协作规范

| instruction                                                                                      | notes                           |
|--------------------------------------------------------------------------------------------------|---------------------------------|
| 主AI职责 - 定义审查清单,明确审查关注点、检查项、评分标准和决策规则                                                             | 一次性传递完整审查要求                     |
| Codex职责 - 执行深度审查分析,使用sequential-thinking进行推理,输出评分、建议和论据                                          | 充分利用Codex推理能力                   |
| 审查清单必须包含:需求字段完整性(目标、范围、交付物、审查要点)、覆盖原始意图无遗漏或歧义、交付物映射明确(代码、文档、测试、验证报告)、依赖与风险评估完毕、审查结论已留痕(含时间戳与责任人) | 缺项时主AI需补充                       |
| Codex审查输出:技术维度评分(代码质量、测试覆盖、规范遵循)、战略维度评分(需求匹配、架构一致、风险评估)、综合评分(0-100)、明确建议(通过/退回/需讨论)、支持论据和关键发现    | 完整结构化输出                         |
| 主AI调用Codex MCP执行审查,传递完整审查清单与验收标准                                                                 | 审查执行沿用 `mcp__codex__codex` 调用格式 |
| Codex生成 `.claude/review-report.md` 审查报告,包含:元数据、评分详情(技术+战略+综合)、明确建议、核对结果、风险与阻塞、留痕文件、反馈通道          | 结果可追溯                           |
| 主AI决策规则:综合评分≥90分且Codex建议"通过"→直接确认通过;综合评分<80分且Codex建议"退回"→直接确认退回;其他情况(80-89分或建议"需讨论")→仔细审阅报告后决策   | 信任明确案例,聚焦边界案例                   |
| 主AI保留随时推翻Codex建议的权力,但需记录推翻原因用于优化Codex审查标准                                                        | 最终决策权在主AI                       |

## 👥 职责分离详细规范

### 主AI（Claude Code）- 规划者 + 执行者

- ✅ 任务规划和拆解（使用 TodoWrite）
- ✅ **直接代码编写**（使用 Read/Edit/Write，无 MCP 延迟）
- ✅ 简单逻辑实现（CRUD、格式化等，<10 行核心逻辑）
- ✅ 最终决策确认（基于 Codex 建议）
- ✅ 决策记录留痕（operations-log.md）
- ✅ 使用 sequential-thinking 进行任务规划推理

### Codex（支持AI）- 分析者 + 审查者

- ✅ **深度推理分析**（使用 sequential-thinking，这是核心优势）
- ✅ **全面代码检索**（充分时间进行代码库扫描）
- ✅ 复杂逻辑设计（算法、架构决策，>10 行核心逻辑）
- ✅ 上下文收集和分析（输出到 `.claude/context-*.json`）
- ✅ 质量审查评分（代码审查、风险识别）
- ✅ 技术建议输出（非决策，是输入）

### 关键边界规则

1. **强制前置**：主AI 编码前必须有 Codex 的分析报告
2. **复杂度阈值**：>10 行核心逻辑必须委托 Codex 设计
3. **质量闸门**：所有代码必须经 Codex 审查
4. **决策留痕**：主AI 可推翻 Codex 建议，但必须记录原因

## 🔄 完整协作流程

### 阶段0：需求理解与上下文收集

- 快速通道：简单任务（<30字，单一目标）直接进入上下文收集
- 复杂任务：先结构化需求（生成 `.claude/structured-request.json`）
- 上下文收集：Codex 执行结构化快速扫描 → 主AI 识别关键疑问 → Codex 针对性深挖（≤3次）→ 主AI 充分性检查

### 阶段1：任务规划

- 主AI 使用 sequential-thinking 分析 Codex 提供的上下文
- 主AI 使用 TodoWrite 记录任务计划和验收标准
- 基于完整上下文定义接口规格、边界条件、性能要求、测试标准

### 阶段2：代码执行

- **主AI 直接编码**（使用 Read/Edit/Write，无 MCP 延迟）
- 简单逻辑（<10 行）：主AI 直接实现
- 复杂逻辑（>10 行）：调用 Codex 设计，主AI 实现
- 实时更新 `coding-progress.json` 状态
- 遇到问题时调用 Codex 分析

### 阶段3：质量验证

- 主AI 定义审查清单与决策规则
- Codex 使用 sequential-thinking 深度审查并生成评分+建议（写入 `.claude/review-report.md`）
- 主AI 基于建议快速决策：
    - ≥90分且建议"通过" → 直接确认通过
    - <80分且建议"退回" → 直接确认退回
    - 80-89分或建议"需讨论" → 仔细审阅后决策

## 📁 文件管理和状态同步

### 路径规范

所有任务执行产生的工作文件必须写入项目本地 `.claude/` 目录（而非全局 `~/.claude/`）：

```
<project>/.claude/
├── context-initial.json ← 初步收集（Codex 输出）
├── context-question-N.json ← 深度分析（Codex 输出）
├── coding-progress.json ← 实时编码状态（主AI 输出）
├── operations-log.md ← 决策记录（主AI 输出）
├── review-report.md ← 审查报告（Codex 输出）
└── codex-sessions.json ← 会话管理（Codex 持久化）
```

### 上下文同步和状态管理

**共享状态文件**（`.claude/` 目录）：

- `context-*.json`：Codex 输出的分析上下文（主AI 只读）
- `operations-log.md`：主AI 记录的决策和进度（Codex 可读）
- `coding-progress.json`：实时编码状态（主AI 维护）

```json
{
  "current_task_id": "task-123",
  "files_modified": ["src/foo.ts"],
  "last_update": "2025-10-03T10:30:00Z",
  "status": "coding|review_needed|completed",
  "pending_questions": ["如何处理边界情况X？"],
  "complexity_estimate": "simple|moderate|complex"
}
```

**同步时序**：

1. Codex 分析完成 → 写入 `context-*.json` → 主AI 读取开始编码
2. 主AI 编码中 → 更新 `coding-progress.json` → Codex 可监控
3. 主AI 完成编码 → 标记 `review_needed` → 触发 Codex 审查
4. Codex 审查完 → 写入 `review-report.md` → 主AI 读取决策

## 🔧 MCP 调用规范

### 首次调用（创建新会话）

- 工具：`mcp__codex__codex`
- 必需参数：`prompt`（任务描述）
- 推荐参数：
    - `model`："gpt-5-codex"（默认）/ "o3" / "o4-mini"
    - `sandbox`："danger-full-access"（默认）/ "read-only" / "workspace-write"
    - `approval-policy`："on-failure"（推荐）/ "untrusted" / "never"

### conversationId 获取方法

**职责分离**：

- **主AI**：生成task_marker、调用Codex、记录conversationId
- **Codex**：查询conversationId、持久化到文件、返回给主AI

**主AI操作**：

1. 生成唯一task_marker：`[TASK_MARKER: YYYYMMDD-HHMMSS-XXXX]`
2. 将task_marker嵌入prompt开头（第一行）
3. 调用mcp__codex__codex
4. 从响应提取`[CONVERSATION_ID]: xxx`
5. 记录conversationId用于后续codex-reply调用

**Codex操作**（在prompt末尾要求）：

1. 提取task_marker（prompt第一行）
2. 查询conversationId：遍历`~/.codex/sessions`目录下最近5个会话文件，匹配task_marker
3. 持久化到`.claude/codex-sessions.json`
4. 在响应末尾附加：`[CONVERSATION_ID]: <conversationId>`
5. 如果未找到：`[CONVERSATION_ID]: NOT_FOUND`

**继续会话**（codex-reply）：

- 使用之前记录的conversationId
- 调用`mcp__codex__codex-reply(conversationId=xxx, prompt=yyy)`
- 无需从响应提取conversationId

**异常处理**：

- NOT_FOUND：记录到operations-log.md，创建新会话
- 持久化失败：记录警告，不影响当前任务执行
- 主AI不得执行会话ID提取脚本，所有查询由Codex完成

### 上下文收集前置原则

- 必须先通过 Codex 收集完整上下文并写入 `.claude/` 文件，再进行任务规划。
- 主AI读取上下文摘要，Codex 执行时读取完整上下文文件，避免信息经主AI转述损耗。

## 🤖 自动化执行策略

**核心原则：默认自动执行，极少数例外才需确认**

**绝对不需要确认的场景**（使用 `approval-policy="on-failure"` 或 `"never"`）：

- ✅ 所有文件读写操作（在 sandbox="danger-full-access" 模式下）
- ✅ 标准工具调用（code-index、exa、grep、find 等）
- ✅ 按既定计划执行的所有任务步骤
- ✅ 代码编写、修改、重构
- ✅ 文档生成和更新
- ✅ 测试执行和验证脚本运行
- ✅ 依赖安装和包管理操作
- ✅ Git 操作（add、commit、diff、status 等，push 除外）
- ✅ 构建和编译操作
- ✅ 任务规划和分解、上下文收集、深度思考推理、质量验证审查
- ✅ 错误修复和重试（最多3次）
- ✅ 调用 mcp__codex__codex 或 codex-reply

**极少数例外情况**（仅这些才需要 Codex 主动请求确认）：

- ⚠️ 删除核心配置文件（package.json、tsconfig.json、.env 等）
- ⚠️ 数据库 schema 的破坏性变更（DROP TABLE、ALTER COLUMN 等）
- ⚠️ Git push 到远程仓库（特别是 main/master 分支）
- ⚠️ 连续3次相同错误后需要策略调整
- ⚠️ 用户明确要求确认的操作

**主AI职责边界**：

- 规划阶段：需要确认技术方案和架构选型
- 执行阶段：完全自动化，Codex 自主决策实现细节
- 验证阶段：自动评分，仅边界案例（80-89分）才人工决策

## 📋 渐进式上下文收集流程

### 核心哲学

- **问题驱动**：基于关键疑问收集，而非机械执行固定流程
- **充分性优先**：追求"足以支撑决策和规划"，而非"信息100%完整"
- **动态调整**：根据实际需要决定深挖次数（建议≤3次），避免过度收集
- **成本意识**：每次深挖都要明确"为什么需要"和"解决什么疑问"

### 步骤1：结构化快速扫描（必须）

通过 Codex 进行框架式收集，输出到 `.claude/context-initial.json`：

- 位置：功能在哪个模块/文件？
- 现状：现在如何实现？找到1-2个相似案例
- 技术栈：使用的框架、语言、关键依赖
- 测试：现有测试文件和验证方式
- **观察报告**：Codex 作为专家，报告发现的异常、信息不足之处和建议深入的方向

### 步骤2：识别关键疑问（必须）

主AI使用 sequential-thinking 分析初步收集和观察报告，识别关键疑问：

- 我理解了什么？（已知）
- 还有哪些疑问影响规划？（未知）
- 这些疑问的优先级如何？（高/中/低）
- 输出：优先级排序的疑问列表

### 步骤3：针对性深挖（按需，建议≤3次）

仅针对高优先级疑问，通过 Codex 深挖：

- 聚焦单个疑问，不发散
- 提供代码片段证据，而非猜测
- 输出到 `.claude/context-question-N.json`
- **成本提醒**：第3次深挖时提醒"评估成本"，第4次及以上警告"建议停止，避免过度收集"

### 步骤4：充分性检查（必须）

在进入任务规划前，主AI必须回答充分性检查清单：

- □ 我能定义清晰的接口契约吗？（知道输入输出、参数约束、返回值类型）
- □ 我理解关键技术选型的理由吗？（为什么用这个方案？为什么有多种实现？）
- □ 我识别了主要风险点吗？（并发、边界条件、性能瓶颈）
- □ 我知道如何验证实现吗？（测试框架、验证方式、覆盖标准）

**决策**：

- ✓ 全部打勾 → 收集完成，进入任务规划和实施
- ✗ 有未打勾 → 列出缺失信息，补充1次针对性深挖

### 回溯补充机制

允许"先规划→发现不足→补充上下文→完善实现"的迭代：

- 如果在规划或实施阶段发现信息缺口，记录到 `operations-log.md`
- 补充1次针对性收集，更新相关 context 文件
- 避免"一步错、步步错"的僵化流程

### 禁止事项

- ❌ 跳过步骤1（结构化快速扫描）或步骤2（识别关键疑问）
- ❌ 跳过步骤4（充分性检查），在信息不足时强行规划
- ❌ 深挖时不说明"为什么需要"和"解决什么疑问"
- ❌ 主AI自行收集代码/文档，必须委托 Codex 执行
- ❌ 上下文文件写入错误路径（必须是 `.claude/` 而非 `~/.claude/`）

## 📊 评分和决策机制

### 评分维度

**技术维度评分**：

- 代码质量：可读性、维护性、性能
- 测试覆盖：单元测试、集成测试、边界条件
- 规范遵循：编码标准、架构原则、安全要求

**战略维度评分**：

- 需求匹配：功能完整性、用户体验
- 架构一致：系统设计、模块化程度
- 风险评估：潜在问题、扩展性、兼容性

**综合评分**：0-100分

### 决策规则

- **≥90分且建议"通过"** → 直接确认通过
- **<80分且建议"退回"** → 直接确认退回
- **80-89分或建议"需讨论"** → 仔细审阅后决策

### 留痕要求

- 所有决策必须记录到 `operations-log.md`
- 推翻 Codex 建议时必须记录详细理由
- 保留完整的审查报告和评分依据

## 🎯 使用示例

### 深度分析示例

```
使用 codex-collaboration skill 分析项目架构，识别潜在的性能瓶颈和改进机会
```

### 复杂设计示例

```
使用 codex-collaboration skill 设计一个支持高并发的分布式任务队列系统
```

### 代码审查示例

```
使用 codex-collaboration skill 审查用户认证模块的代码质量和安全性
```

---

*本 skill 专注于 Codex 协作流程，确保深度分析、复杂设计和质量审查的标准化和高效执行。*
