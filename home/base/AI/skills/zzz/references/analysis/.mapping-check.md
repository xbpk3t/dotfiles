---
name: mapping-check
role: atom
description: 只验收 mapping artifact 是否合规；不重写 map；标准唯一服从 mapping.md
---

# mapping-check — 契约验收（只验不写）

**是什么：** 对已有 mapping 输出做 **pass/fail 检查**（形态、闸门、毒码、拍 B、落盘）。
**不是：** 第二套 mapping；不联网核查技术事实；默认不重做 map。

**标准唯一来源：** 同目录 [mapping.md](mapping.md)。本文只列检查项，**不另立规则**。mapping.md 与本文冲突时以 mapping.md 为准。

**输入：** 用户粘贴的完整 mapping 输出（含拍 A；若有拍 B 一并贴）。可声明「仅 A」或「A+B」。
**默认禁止落盘。**

---

## 硬约束

1. **只验收**：输出 verdict + checklist；**禁止**默默重写整份 topic-map。
2. 用户明确要求「按 must_fix 修一版」时，可另开 `/zzz mapping` 或极短修补说明，**本步仍先给检查结果**。
3. 不读、不依赖外部盘点/库存路径；不对照「标准答案内容是否与某次历史 run 一致」，只验 **契约**。
4. 内容质量（步骤是否真同构）若明显假：标 fail + 毒码/廉价还原；不做技术论文。

---

## 检查清单（按序）

### 拍 A（必查）

| id | 项 | pass 条件 |
|----|-----|-----------|
| A1 | 形态 | 有 `## artifact` / `step: mapping` / `status` |
| A2 | 主轴字段 | 有结构/另一层/主轴（或等价清晰表述） |
| A3 | layer_kind | `cross` 或 `instance` |
| A4 | score | 整数 1–5；未省略；未见无脑固定 3 的敷衍（结合 A5） |
| A5 | score≥4 | 有一句 score 依据（或等价「为何不是 ±1」） |
| A6 | boundary | 有；半轴/instance 非空话 |
| A7 | 差分闸 | 有 **继承 / 新变量 / 失效点**；instance 的新变量与失效点有实质 |
| A8 | score≥4 差分 | 新变量或失效点至少一格实质（不能双「无」糊弄） |
| A9 | 步骤/Q-iso | ≥3 步味，含判定或失败/终止；非空「开始-中间-结束」 |
| A10 | 毒码/还原 | 无 D/I/K/P/C/S；无「不就是」无步骤 |
| A11 | 单主轴 | 无多机制拼盘 |
| A12 | 落盘 | 声称或迹象写了 yml/data/gh → fail（本检查场景默认禁落盘） |

### 拍 B（仅当输入含 handle/candidates 或用户声明 A+B）

| id | 项 | pass 条件 |
|----|-----|-----------|
| B1 | 触发合理 | 有 ≥2 源或用户明确要求；非无故灌抓手 |
| B2 | handle | 名/结构/来自/score/适用范围/反例或边界 |
| B3 | 来自 | ≥2 个已对齐 case |
| B4 | candidates | 存在则标待验证；**未**写成 status ok 的完整 map |
| B5 | next | 有回炉/改 handle 意向 |

无拍 B 内容 → `拍B: skipped — 输入无抓手块`。

---

## 输出格式（可读优先）

```text
## artifact
step: mapping-check
status: pass | pass_with_nits | fail
scope: A | A+B

### 结论
一句：是否可当合规 mapping 输出。

### 检查表
| id | 结果 | 备注 |
|----|------|------|
| A1 | pass/fail | … |
| … | … | … |

### 必须修（fail 时）
- …

### 建议（nits，不单独导致 fail）
- …

### 毒码命中
无 | D/I/K/P/C/S + 摘录

### 落盘
pass | fail

### next（推进 hint）
- fail → 按 must_fix 再 `/zzz mapping`；且先别拍 B
- pass_with_nits → 可改 nits 或忽略；然后：再 map 对端 / 拍 B（若已 ≥2 同轴）/ 停
- pass → 同「用法 workflow」：再 map | 拍 B | 停（不必再 check）
```

- `pass`：必查项全过
- `pass_with_nits`：必查过，仅有建议
- `fail`：任一项必查失败

**禁止**在本 artifact 里贴一整份「优化后的 mapping」 unless 用户本轮明确要求修复。

---

## 与 mapping 自检 / 用法的关系

- `/zzz mapping` 必有 `### self-check` + `### next`（作者自检与推进）。
- `/zzz mapping-check` = **按需判卷**（回归、存疑、高分锚点、落盘前），**不是**每次 map 后的默认下一步。
- 完整阶段表见 [mapping.md](mapping.md) 文首「用法 workflow」。
