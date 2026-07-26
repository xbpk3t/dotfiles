---
name: recall
role: composite
description: >
  闭卷召回：出题→作答→批改→gap 收敛；类比/mapping 仅用户确认后 sub-agent。
  Teach=3w3h / Test=mdscc（双切，不并）。不写 recall 落盘、不改 data/gh。
pipeline:
  - analogy
  - mapping
---

# recall — 闭卷召回

```text
出题 → 停等作答 → 批改(0/1/2 + gap)
  → [gap 未闭合] 最多 1–2 轮追问 verify
  → 询问 类比 / mapping / 展开
  → 用户确认后 fan-out pipeline sub-agent → 合并
  → next hint
```

**禁止**先讲、先搜标准答案全文、先贴 mdscc 答案。
**禁止**父 agent 在用户未确认时输出类比/mapping 长文，或未起 sub-agent 却伪造 pipeline 产物。

---

## 0. 坐标系（双切，不并）

| 层 | 职责 |
|----|------|
| **3w3h** | Teach / 说明切；副标签最多 |
| **mdscc** | Test / 闭卷骨架；**主 role** = `meta \| derive \| sol \| cost \| case \| l3` |
| **kind** | topic 持有策略；影响是否强依赖已有 mdscc |
| **qs** | 题面细节；**不**挂完整 mdscc 五键 |

- topic 级 **meta 全 topic 共用一条**；qs 没有自己的 mdscc.meta。
- 若 data/gh **无 mdscc**：可从 why/ww/qs **推断临时 spine**，标明 `spine: inferred`；主 role 词表仍用 mdscc，**不要**改考 3w3h 六字段当主 role。
- 重叠是提炼关系（meta←why，case←ww），**不是**字段别名；禁止把 mdscc 并进 3w3h。

---

## 1. 出题

- 每轮优先 **1** 题；用户明确要求多题再多抛（批改仍逐题）。
- 题源：当前 topic、`data/gh` 的 `qs` / `ww` / 3w3h 条目、或用户指定范围。
- 有上下文时标明来源（如「来自 ww」「来自 qs」）；声明建议的 **主 role**（只给 role 词，不泄露答案要点）。

发出题面后附答题格式，然后 **停止等待**。

**首轮出题结束时（用户尚未作答）必须**声明 pipeline 未启用，例如：

```text
skipped: analogy — 用户未确认（出题阶段）
skipped: mapping — 用户未确认（出题阶段）
```

禁止在首轮跑 analogy/mapping；也禁止完全不提 pipeline 状态。

### 答题格式

```text
role: meta | derive | sol | cost | case | l3
上挂: <topic>（<kind>）——该停在哪一层
闭卷-meta: （该 topic 的元问题，一句；可全 topic 共用同一句）
闭卷-本题: （直接回答题面）
可选-maps: （一句异层同构；不会就写「无」或「想知道」）
```

### role 规则

- **主 role 用 mdscc**；**3w3h 只作副标签**（例：`role: sol`（副 hti））。
- `l3` = 跨挂 / maps 向；题面是 ops/CLI/监控时，批改 **禁止**建议改 `mdscc.meta`。
- meta 必须是 **一句** 第一性原理式问题；禁止 FAQ / 步骤 / 监控清单。

---

## 2. 批改

仅在用户交卷后进行。可轻量核对硬事实；网络不可用则标 offline，不挡批改。

### 分数与 gap（score-driven）

| 分 | 含义 | gap |
|----|------|-----|
| **0** | 方向错、当 FAQ/清单、零关键词、空白 | **必有 gap**（列条） |
| **1** | 方向有但与骨架/题面错位、绝对化、漏关键词 | **列具体 gap** |
| **2** | 主 role 合理 + 贴 meta 精神 + 本题在点上 | gap 可空或 polish |

**gap** = 本轮 0/1 分点对应的可修正缺口（role / 上挂 / 关键词 / 绝对化 / 假 maps），**不是**「整章不会」。

### 必查

- **上挂仪式**：是否挂到对的 topic/层
- **role**：是否 mdscc 主 role；3w3h 仅副
- **case 绝对化**：禁止「凡 XX 品类都要/都不要」；用 **需求语言**
- **题面关键词是否答全**
- **过满表述**：方向半对也要降分并点破
- 骨架建议最多口头一句；**默认不写** `data/gh` / wiki

### 批改输出

逐题：role、meta/上挂、本题贴题与否、maps 质量、**分 0/1/2**、**gap 列表**（可空）。
多题：总分表 + 本轮习惯结论。

用户写 maps「不知道/想知道」时：批改里 **可以先给一句合格 maps 供对照**；要展开多条同构或类比表，必须走第 4 步询问 + pipeline。

---

## 3. 收敛（sigma-inspired mini loop）

**取：** 1–2 问/轮、针对 gap 追问、mastery 后再下一题。
**不取：** roadmap/profile 落盘、HTML、跨 session resume、完整 diagnose 问卷。
**不要**用 `/sigma` 替代本 skill（sigma 不认 kind/mdscc/maps）。

规则：

1. 若本题 **gap 非空** 且用户未声明跳过：最多 **1–2 轮** 定向追问（只问不灌答案），再根据新答更新分与 gap。
2. **Mastery 门槛**：本题达 **2 分**，或用户明确「跳过/下一题」→ 才出下一题。
3. 追问轮次用尽仍 <2：在批改结论中标 `mastery: open`，进入第 4 步询问（类比/mapping/展开）帮助补 gap，**不要**假装已掌握。

---

## 4. 询问（批改/收敛后必做）

默认都不做；可多选：

1. 是否需要 **【类比】**（→ pipeline `analogy`）？
2. 是否需要 **【mapping】**（→ pipeline `mapping`）？
3. 是否需要就 **gap** 做简短 **【展开】**（父 agent 短讲，不走 pipeline）？

**未明确同意前，禁止**输出类比列表正文、mapping 展开、或长讲解。

---

## 5. Pipeline：analogy / mapping（须 sub-agent）

| 用户确认 | 父 agent 动作 |
|----------|----------------|
| 要类比 | 起 sub-agent 跑 `analogy`（`nu …/zzz.nu … analogy` → Read body）；只传 topic、本题、gap、统一 case 约束 |
| 要 mapping | 起 sub-agent 跑 `mapping`；强调 **topic 级先、qs 级步骤对应** |
| 都不要 | `skipped: analogy — 用户未确认` / `skipped: mapping — 用户未确认` |
| 只要其一 | 另一项 skipped |

- 两步无数据依赖时可 **并行**。
- 父 agent **汇合**后展示 artifact；**禁止**与 artifact 矛盾或心算重写长文。
- 规则与 case 见：
  - [analogy.md](analogy.md)
  - [mapping.md](mapping.md)

### mapping 分层（父 agent 验收时核对）

- **topic**：整体控制结构同构
- **qs**：仅本题机制/步骤对应；禁止 qs 另起无关域整套 mapping
- **类比**：同一 case 贯穿；禁止多工具 mechanism 拼盘

### 展开（仅当用户要【展开】）

只针对 **gap** 短讲；禁止整章重讲；禁止偷渡未确认的类比/mapping 长文。

---

## 6. 本轮结束与 next

点头项（pipeline / 展开）输出完即收束。
同对话续练：可针对 gap 再出 1 题（仍闭卷）。无跨 session 自动 resume。

```text
## next
- 下一题方向: …
- 建议回看 mdscc 键: … | spine: inferred/authoritative
- write: 默认不写 data/gh
- skip: …
```
