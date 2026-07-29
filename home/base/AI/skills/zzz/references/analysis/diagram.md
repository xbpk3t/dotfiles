---
name: diagram
role: atom
description: how-it-works 图入口；委托 diagram-picker（图种/工具/源文件/SVG）；产出供 3w3h hti 合并的 artifact
---

# diagram — how it works（委托 diagram-picker）

本步 **不** 自建画图引擎。目标：为当前 topic 画 **一张** 说明「怎么 work」的运行时图，并交给 3w3h / 用户阅读。

## 执行（强制）

1. **加载并执行 skill：`diagram-picker`**（当前 session 可用 skills 列表中的同名 skill）。
    - 必须调用 Skill 工具尝试加载 diagram-picker；不可因「推测不可用」跳过调用。确认不可用后（Skill 调用被拒绝或不可见）才走 fallback。
2. 向 diagram-picker 传入至少：
   - **intent:** `how-it-works`
   - **topic / 要回答的问题：**（一句，如「Agent 单轮 tool call 时序」）
   - 用户若指定图种或工具，原样转发
3. 要求 diagram-picker 按该 skill 的 workflow 完成：选图种 → 选工具 → 写源文件 → 渲染 SVG → **Type choice + Captions(3–5) + Out of scope**。
4. 构件分解（`X = A + B + C`）**不是**本步；那是 `brk`。本步只跑运行时 / 协作 / 状态。

## 若 diagram-picker 不可用

在本 session **找不到** `diagram-picker` 时：

  ### Fallback 执行步骤

  #### Step 1: 图前择型（必须，在画图前执行）

  在输出 Mermaid 图之前，先明确回答：

  | 维度 | 选项 | 本图选择 | 理由 |
  |---|---|---|---|
  | 图种 | sequence / state / flowchart | <选一个> | <一句为什么此图种优于另两种> |
  | 工具 | mermaid / plantuml / d2 | mermaid | <一句为什么选此工具> |

  理由维度参考：
  - **图种**：sequence = 时间线/协议/调用链；state = 状态机/生命周期；flowchart = 分支/决策/流程
  - **工具**：对话内仅 mermaid 可渲染且不需要额外环境

  择型表在本步输出，**不** 作为 artifact 的一部分。

- 在 artifact 中声明 `picker: unavailable`
- **Fallback：** 仅在对话内输出一张 **Mermaid** 图（sequence / state / flowchart 三选一，写清选型理由）+ 图注 3–5 + 故意不画的边界
- 不伪造 SVG 路径；不假装已渲染

## 输出 artifact（本步结束时必须给出）

```text
## artifact
step: diagram
status: ok | skipped
picker: used | unavailable
question: <一图一问题>
diagram_type: <sequence|state|flowchart|…>
tool: <mermaid|plantuml|d2|…>
source_path: <若有落盘源文件>
svg_path: <若有 SVG>
type_choice: <一句：为何此图种/工具>
captions:
  - …
out_of_scope:
  - …
```

（可将 diagram-picker 的写-up 原样纳入 captions / out_of_scope；父 agent 合并 3w3h 时用本块。）

（强制：artifact 块必须输出在本对话的回复正文中，**不可写入文件**。父 agent 需要从对话中读取本块合并入 3w3h。）

## 禁止

- 在 zzz 内再维护一套与 diagram-picker 重复的「图种→工具→渲染」规则
- 无图注、无边界的裸图交差
- 把整份 3w3h / 全书架构塞进一张图
