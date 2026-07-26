---
name: verify-chain
description: 验证链 — 角色对抗式技术文章交叉验证。写完IT文章后，Critic 提取关键断言并生成核查问题，多个 Verifier SubAgent 独立上下文联网验证，Repairer 自动修复。用于规避 AI 幻觉、知识过时、信息遗漏。
---

# 验证链（Verify Chain）

> Vendored from gitee.com/qiyisoft001/verify-chain (pin a7506f2) with local path policy for LUC-284.

## 触发条件

当用户明确表示以下意图时调用此技能：
- "验证这篇文章"、"核查文章内容"、"check 文章"、"verify article"
- "检查有没有错误"、"帮我审稿"
- 写完一篇 IT 技术文章后主动询问是否需要验证
- 用户提到 `/verify` 或 `/验证链`

## 适用场景

- IT 技术文章（K8s、Docker、Linux、编程语言、架构设计、DevOps 等）
- 技术教程、操作指南、最佳实践文档
- 技术博客、技术对比评测

## 不适用场景

- 纯理论/学术论文（需要专家同行评审，AI 无法替代）
- 非技术类内容（散文、小说、新闻评论）
- 纯个人经验分享（"我在项目中遇到的一个坑"——个人经历无法核查）

## 产物落盘（强制）

**所有中间物与终产物必须写到 `/tmp`，禁止污染工作区。**

### 目录规则

1. **根目录**：`/tmp/verify-chain/`（不存在则创建）
2. **本次 run 目录**：`/tmp/verify-chain/YYYYMMDD-<slug>/`
   - `YYYYMMDD`：本机本地日期（如 `20260723`）
   - `<slug>`：源文章文件名去掉扩展名后规范化为 `[a-z0-9-]`，截断约 40 字符；无文件名时用短标题 slug 或 `article`
3. **同日同 slug 再跑：覆盖**该目录内容（先写新文件，不另开子目录）
4. 开始阶段 1 前先 `mkdir -p` 本次 run 目录

### 必须写入 run 目录的文件

| 文件 | 阶段 | 说明 |
|------|------|------|
| `assertions.md` | Critic 后 | 结构化断言列表（若有） |
| `verification-results.md` | Verifier 后 | 全部核查结果汇总（若有） |
| `article-verified.md` | Repairer 后 / 只查时用原文+报告 | 修复后文章；只查不改时仍可写对照稿或跳过 |
| `verification-report.md` | 报告阶段 | 完整核查报告（断言 + 结论 + 来源） |

「只查不改」时至少写 `verification-report.md`（及已有的 assertions / results）。

### 禁止

- **禁止**在 cwd、仓库根、文章旁创建 `.verify-chain-tmp` 或任何 hidden 工作区目录
- **禁止**默认把终稿写回 wiki/docs 或源文章同目录
- **禁止**仅用相对路径文件名落盘（如直接 `./article-verified.md`）——必须用上述绝对路径
- 仅当用户**明确指定**写回路径时，才额外复制/写入该路径

### 对用户展示

报告阶段除摘要外，必须列出本次产物的**绝对路径**列表，例如：

```
产物目录: /tmp/verify-chain/20260723-kde-vs-gnome/
- /tmp/verify-chain/20260723-kde-vs-gnome/verification-report.md
- /tmp/verify-chain/20260723-kde-vs-gnome/article-verified.md
```

## 执行流程

### 阶段 1：Critic — 断言提取

```
使用 Critic System Prompt（prompts/critic.md）
输入：完整文章 Markdown
输出：10-20 个关键断言，按 6 类标注
```

**执行方式**：串行。这是整个流程的入口，必须先完成。

**输出解析**：从 Critic 的输出中解析出每个断言的结构化数据（编号、原文摘录、类别、核查问题、建议核查路径）。

如果 Critic 返回的断言数量 < 5，重新执行一次 Critic，要求它更仔细地审查。

有断言列表后写入：`/tmp/verify-chain/YYYYMMDD-<slug>/assertions.md`。

### 阶段 2：Verifier — 并行交叉验证

```
使用 Verifier System Prompt（prompts/verifier.md）
对每个断言启动一个独立 SubAgent
SubAgent 需携带联网搜索能力
```

**执行方式**：所有 Verifier SubAgent 并行启动。

**关键要求**：
- 每个 SubAgent 使用**独立的对话上下文**（Agent 工具默认行为）
- 每个 SubAgent 携带 Verifier System Prompt + 单个断言的数据
- SubAgent 需要联网搜索权限（WebSearch + WebFetch 工具）
- 禁止 Critic 的输出和原文全文进入 Verifier 上下文（仅携带其负责的单个断言）

**并发控制**：
- 默认同时启动全部 SubAgent
- 如果断言数量较多（>15），可分批启动（每批 10 个）

**输出收集**：等待所有 SubAgent 完成后，按编号收集核查结果，写入
`/tmp/verify-chain/YYYYMMDD-<slug>/verification-results.md`。

### 阶段 3：Repairer — 自动修复

```
使用 Repairer System Prompt（prompts/repairer.md）
输入：原始文章全文 + 所有核查结果
输出：修复报告 + 修复后文章
```

**执行方式**：串行。必须在所有 Verifier 完成后执行。

**筛选输入**：只将有问题的核查结果（⚠️ 不完整 / ❌ 错误 / ❓ 无法确定）传给 Repairer。✅ 准确的断言不需要修复。

将修复后全文写入：`/tmp/verify-chain/YYYYMMDD-<slug>/article-verified.md`。

### 阶段 4：报告

向用户展示：

1. **核查摘要**：
   - 总共验证了 N 个断言
   - ✅ 准确：X 个
   - ⚠️ 不完整：Y 个
   - ❌ 错误：Z 个
   - ❓ 无法确定：W 个

2. **修复清单**：哪些问题已自动修复

3. **待人工确认项**：❓ 无法确定的内容

4. **输出文件（绝对路径）**：
   - `/tmp/verify-chain/YYYYMMDD-<slug>/article-verified.md`：修复后的文章
   - `/tmp/verify-chain/YYYYMMDD-<slug>/verification-report.md`：完整核查报告（含所有断言 + 核查结论 + 来源）
   - 同目录下其他中间物（若有）

完整报告正文写入 `verification-report.md`（绝对路径如上）。

## 用户交互规则

- **默认全自动执行**：Critic → Verifier × N → Repairer → 报告，中间不询问用户
- **如果用户说"先审再改"**：阶段 2 完成后暂停，展示核查结果让用户审核，由用户决定哪些要修复，再进入阶段 3
- **如果用户说"只查不改"**：跳过阶段 3，只输出核查报告（仍写入 `/tmp/.../verification-report.md`）
- **如果用户标注了特定关注点**（如"重点检查命令参数"）：在阶段 1 中将用户指示传递给 Critic

## 核心设计原则

1. **角色分离**：Critic 只提问不回答，Verifier 只核查不修改，Repairer 只修复不质疑
2. **上下文隔离**：每个 Verifier 独立上下文，避免 Critic 的偏见"传染"给 Verifier
3. **联网优先**：所有核查必须基于联网搜索结果，不得仅凭模型内置知识
4. **权威来源**：严格区分可信来源和内容农场，宁缺毋滥
5. **最小修复**：只改有问题的部分，保持原文风格
6. **工作区清洁**：产物只进 `/tmp/verify-chain/`，不污染用户仓库或 cwd
