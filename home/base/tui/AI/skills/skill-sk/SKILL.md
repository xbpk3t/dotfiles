---
name: skill-sk
description: 编写与维护 skills 的流程与规范。当用户要求创建/更新/优化 skill、讨论 SKILL.md、best practices、gotchas、schema、触发条件、目录结构或需要可复用 workflow 时必须使用。也用于把已有说明整理成结构化的 skill 资产（SKILL.md + references/）。
---

# Skill SK

## 适用范围

- 创建新 skill 或改造现有 skill（SKILL.md + references/ + 可选 scripts/assets/templates）。
- 对 skill 的 trigger、scope、output format、quality checks 做结构化整理。
- 把长说明拆分为可复用的 references，并在 SKILL.md 中提供清晰入口。

## 语言与表达

- 输出以中文为主，技术术语使用 English。
- 指令使用祈使句，语气明确、可执行。
- SKILL.md 需要短、硬、具体；长内容放 references/。

## 工作流（按顺序）

1) 意图捕获：明确 skill 的 job-to-be-done、trigger、inputs、outputs、non-goals。
2) 仓库检索：检查现有 skills，复用命名与结构，避免重复。
3) 结构设计：确定 SKILL.md 章节、是否需要 scripts/assets/templates。
4) 编写 SKILL.md：只放核心流程、规则、输出模板与引用方式。
5) 准备 templates：
   - 需要结构化 YAML 时，从 templates 拷贝骨架再填充。
6) 自检：按 quality checks 核对覆盖范围、触发清晰度与格式稳定性。

## Templates（按需使用）

- `templates/best-practices.yaml`：best practices 结构模板。
- `templates/gotchas.yaml`：gotchas 结构模板。
- `templates/schema.yaml`：schema 结构模板。

## Best Practices

### 定位与触发（positioning）

- [MUST] 单一 job-to-be-done：一个 skill 只解决一个明确问题，避免把多个不相干任务混在一起。
- [MUST] description 写触发条件：必须包含何时使用的语境与关键词，不能写成宣传语。
- [SHOULD] 避免一次性 prompt：适用于可复用 workflow，不要把一次性需求做成 skill。
- [SHOULD] 写清 non-goals：明确不做什么，避免 scope 膨胀导致触发混乱。

### 写法与表达（authoring）

- [MUST] 祈使句指令：使用明确动作指令，避免模糊描述。
- [MUST] SKILL.md 只放核心控制面：长说明和背景知识不要堆在 SKILL.md。
- [MUST] 输出格式钉死：若有格式要求，必须给出模板或字段顺序。
- [SHOULD] 用 examples 代替空泛要求：给最小可行 Input/Output 示例。
- [MUST] 中文为主、English 术语：减少歧义，保持术语准确。

### 资源组织（resources）

- [MUST] references 放知识：references/ 仅供模型读取，不作为输出素材。
- [SHOULD] assets 放输出素材：模板/素材放 assets/，避免与 references 混用。
- [SHOULD] scripts 只做确定性步骤：可重复、可验证流程优先脚本化。
- [MUST_NOT] 避免深层跳转：SKILL.md 直接指向必要参考文件。
- [SHOULD] 模板优先复用：可复用格式优先做成 templates/。

### 质量与迭代（quality）

- [MUST] 写入 quality checks：自检项必须可执行。
- [SHOULD] 用真实任务验证：用 3-5 个真实输入验证触发与格式稳定性。
- [SHOULD] 依据失败样例迭代：优先修 trigger、步骤或缺脚本的问题。
- [MUST] 保持结构稳定：章节顺序与字段命名避免无意义改动。

## Gotchas

- scope 过大：试图覆盖多个不相干任务导致 trigger 与输出发散。修复：收敛为单一 job-to-be-done，拆分多个 skill。
- description 写成宣传语：只强调“强大/高效”，没有具体 trigger 语境。修复：写清“何时使用 + 典型语境/关键词”。
- 输出格式不明确：只写“专业清晰”没有字段或模板。修复：给出固定模板或字段顺序。
- 把 skill 当 prompt 垃圾场：堆叠所有要求导致执行发散。修复：保留关键规则，长内容移到 references/。
- 把 references 当输出素材：references/ 被当作最终输出内容。修复：references 只给模型看，输出素材放 assets/。
- 未先检索仓库：未检查已有 skills 导致命名冲突或重复。修复：先扫描现有 skills，复用命名与结构。
- 缺少 quality checks：没有自检项导致结果格式不稳定。修复：写出最小自检清单。

## Schema

- frontmatter.name：skill 标识符，要求与目录名一致；使用 lowercase + kebab-case，作为稳定 key。
- frontmatter.description：触发条件与用途描述（主触发入口）；必须包含何时使用的语境与关键词。
- scope：skill 覆盖范围；单一 job-to-be-done，边界清晰。
- non_goals：明确不做的事项；防止 scope 膨胀。
- inputs：典型输入形式与来源；说明用户常见输入结构或文件类型。
- outputs：预期输出与格式要求；给出模板或字段顺序。
- workflow：核心流程（步骤化）；使用祈使句，保持步骤精简。
- references：需要时加载的参考文件；在 SKILL.md 中明确“何时读取”。
- scripts：可选的确定性脚本；仅用于可重复、可验证步骤。
- assets：输出用素材或模板；与 references 明确区分。
- templates：复用结构或格式骨架；适合输出模板或 YAML 骨架。
- quality_checks：自检清单；覆盖触发、格式、字段完整性。
- language：语言与术语规范；中文为主，技术术语用 English。

## 质量检查（必须完成）

- description 是否包含明确 trigger（可被自动触发）。
- scope 是否单一且边界清晰，non-goals 是否写出。
- outputs 是否有明确格式或模板。
- templates 是否与正文结构一致，且 SKILL.md 不堆长内容。
- 语言是否满足“中文 + English 技术术语”。
