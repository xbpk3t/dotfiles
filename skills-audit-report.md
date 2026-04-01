# `home/base/tui/AI/skills` 技能审计报告

## 范围与方法

本次审计针对 `home/base/tui/AI/skills` 下 17 个自定义 skill，重点看四件事：

1. 这个 skill 现在是否还有明确价值。
2. 它的 `SKILL.md` 是否符合一个可持续维护的 skill 结构，而不是把参考资料整本塞进去。
3. 它是否已经被当前环境里的成熟第三方 skill 或系统能力覆盖。
4. 是否值得继续维护，还是应该合并、替换或归档。

本次结论基于以下信号做判断：

- frontmatter 与目录结构
- `SKILL.md` 行数与章节组织
- `references/`、`scripts/`、`assets/` 等资源拆分情况
- 指令是否混入环境私货、过强约束或别的生态字段
- 与当前会话已提供 skill 的重叠程度

---

## 总结判断

### 一句话结论

这批 skill **有价值，但组合上冗余明显、质量层级不齐，值得做一次中等偏大的结构调整**。
不是“全部推倒重来”，而是：

- 一批直接用成熟 skill 替代
- 一批保留但重构成“短 SKILL.md + references”
- 少数真正有你自己工作流价值的 skill 继续维护

### 组合层面的核心问题

#### 1. 重复建设过多

这 17 个里，有相当一部分名字和当前环境已提供的成熟 skill 直接重合，或者功能上几乎一一对应：

- `ai-tooling-strategy`
- `codex-collaboration`
- `diagram-picker`
- `docs-images-organizer`
- `goreleaser-best-practices`
- `jq`
- `react-doctor`
- `skill-sk`
- `slidev-overlay`
- `taskfile-best-practices`
- `typst`

这类 skill 如果你没有明确的 repo 私有差异，继续自己维护的收益很低，维护成本很高。

#### 2. 多个 skill 把“控制面”和“知识库”混在一起

健康的 skill 通常是：

- `SKILL.md` 只放触发、流程、输出格式、关键规则
- 大段知识、例子、参考语法放 `references/`

但你这里有几份明显是“大型参考文档伪装成 skill”：

- `docker-best-practices` 656 行
- `modern-css` 758 行
- `nushell-best-practices` 659 行
- `jq` 475 行
- `duckdb` 411 行

这会带来三个问题：

- 触发后上下文开销太大
- 模型更像在“读教程”，不是“执行 workflow”
- 一旦知识过时，维护面非常大

#### 3. 元数据生态混杂

有几份 skill 混入了明显不是当前这套 skill 运行时的字段：

- `diagram-picker` 里的 `tool-id`、`tool-binary`、`tool-version`
- `planning-with-files-zh` 里的 `user-invocable`、`allowed-tools`、`hooks`
- `react-doctor` 里的 `version`

这不一定会坏，但会增加两个风险：

- 读的人无法判断哪些字段真的生效
- 迁移环境时容易出现“以为有用，实际没用”的伪配置

#### 4. 少量命名/结构不一致已经是硬问题

- `nushell-best-practices` 目录名与 `frontmatter.name: nushell-pro` 不一致
  这不是风格问题，是稳定标识问题。

- `modern-css` frontmatter 里混入了注释和外链痕迹，表现出“采集资料时直接塞进头部”的痕迹
  可维护性不高，也容易让触发描述失焦。

- `references/.DS_Store` 出现在 `modern-css/references`
  这类噪音应该清掉。

#### 5. 有些规则把特定环境假设写成了通用准则

最典型的是 `docker-best-practices` 开头那段 Windows 路径说明。
这类内容问题不在“对不对”，而在：

- 它不是 Docker skill 的核心
- 它混入了某个工具环境的路径约束
- 放在最开头会污染 skill 的真正职责

同类问题在 `planning-with-files-zh` 里也存在：它把一套插件式 hook/workflow 假设，直接写成了 skill 本体。

---

## 是否需要大范围调整

### 结论

**需要。**

但这里的“大范围调整”不是指逐个重写 17 个 skill，而是做一次组合层面的梳理：

1. 删除/归档一批与成熟 skill 直接重叠的本地副本。
2. 对保留 skill 统一采用同一骨架：
   - 短 frontmatter
   - 短 `SKILL.md`
   - 重知识放 `references/`
   - 可验证步骤放 `scripts/`
3. 明确哪些 skill 是“你的私有工作流资产”，哪些只是“公共知识镜像”。

如果不做这轮整理，后续每加一个 skill，整个 skill 集会继续变重、变散、变难维护。

---

## 建议的组合策略

### A. 直接替换为成熟 skill

这类不建议继续自己长期维护，除非你明确要加 repo 私有约束。

| skill | 判断 | 原因 | 建议 |
| --- | --- | --- | --- |
| `ai-tooling-strategy` | 可替换 | 名称与定位都高度通用，当前环境已有同名成熟 skill | 直接替换；若有私有差异，改成 repo overlay |
| `codex-collaboration` | 可替换 | 内容大而泛，很多规则与系统级 agent 协作指令重叠 | 直接替换或拆成很薄的私有协作补充 |
| `diagram-picker` | 可替换 | 当前环境已有同名 skill；你这版更像一个工具映射器 | 用成熟版；私有映射表若有价值，迁到参考文件 |
| `docs-images-organizer` | 可替换 | 问题域明确，但当前环境已有同名 skill | 直接替换 |
| `goreleaser-best-practices` | 可替换 | 当前环境已有同名 skill，且你这版本身写得已经偏 overlay | 替换；若保留，仅保留 repo 私有约束 |
| `jq` | 可替换 | 当前环境已有同名 skill；你这版知识量大但不一定比成熟版更稳 | 替换；把你自己的模式库单独沉淀 |
| `react-doctor` | 可替换 | 几乎只是工具入口包装 | 直接替换 |
| `skill-sk` | 可替换 | 当前环境已有同名 skill；而且你这版已经很像成熟模板 | 直接替换或作为你自己的中文 overlay |
| `slidev-overlay` | 可替换 | 当前环境已有同名 skill，且这类 overlay 极适合上游维护 | 替换；只保留你的特定问答模板 |
| `taskfile-best-practices` | 可替换 | 当前环境已有同名 skill；这版更像轻量 overlay | 替换；私有约束放 AGENTS 或 repo docs |
| `typst` | 可替换 | 当前环境已有同名 skill，且 Typst 生态更新较快 | 直接替换 |

### B. 有保留价值，但应该重构

这类不是没价值，而是“当前写法不健康”。

| skill | 价值判断 | 主要问题 | 建议动作 |
| --- | --- | --- | --- |
| `docker-best-practices` | 有价值 | 太长、环境私货混入、知识时效性强 | 保留但大改，重构成 Dockerfile/compose/review workflow skill |
| `duckdb` | 有价值 | 更像教程，不像 workflow；安装与示例太重 | 保留，拆分 references，突出“何时选 DuckDB、如何快速落地” |
| `mermaid-diagrams` | 有部分价值 | 与 `diagram-picker` 职责重叠；过于通用 | 若保留，降级成 `diagram-picker` 的 mermaid 专用 reference |
| `modern-css` | 有价值 | 明显过长，像资料摘录；触发边界太宽 | 保留但重构成“现代 CSS 审核/选型”skill，资料全部下沉 |
| `nushell-best-practices` | 有价值 | 过长、名称不一致、教程感过强 | 保留但重构，先修 `name`，再拆 references |
| `planning-with-files-zh` | 有明显私有价值 | hook/插件假设太重，安全面较大，和当前 agent 计划能力有重叠 | 仅在你真的长期使用这套文件规划法时保留，否则降级为模板仓库/文档 |

### C. 建议合并或降级为参考资料

| skill | 建议 | 原因 |
| --- | --- | --- |
| `mermaid-diagrams` | 合并进 `diagram-picker` 或降级到 `references/mermaid.md` | 单独做 skill 的边际收益不高 |
| `modern-css` | 如果你不经常做纯 CSS 评审，可降级为前端 skill 的 reference 包 | 它更像知识库，不像独立工作流 |
| `jq` | 若你舍不得删，可把 Pattern Library 抽成参考资料，而不是继续维持同名 skill | 价值在模式库，不在 skill 壳子 |

---

## 逐项细评

### `ai-tooling-strategy`

- 优点：很短，知道自己该做什么，没有失控膨胀。
- 问题：价值主要来自 `references/`，而不是 skill 本体；且与现有成熟 skill 直接重叠。
- 判断：**存在价值有限，维护价值更低。**
- 结论：**替换为成熟 skill。** 如果你有自己的 MCP 偏好、工具优先级或禁用规则，单独做一个 repo overlay 更合理。

### `codex-collaboration`

- 优点：试图把协作流程系统化。
- 问题：
  - 334 行已经太重。
  - 很多内容和系统级协作指令天然重复。
  - emoji 标题很多，信息密度并没有因此更高。
  - 容易把“当前环境行为准则”再重复一遍，形成双重约束。
- 判断：**保留收益不高，容易和系统 prompt 打架。**
- 结论：**建议替换。** 如果真要留，只保留你自己的差异化约束，例如“何时强制产出文件化计划”“何时必须二次审查”。

### `diagram-picker`

- 优点：结构清楚，知道要靠 `references/*.yaml` 做单一真相源。
- 问题：
  - 有明显外部生成痕迹：`tool-id`、`tool-binary`、`tool-version: unknown`。
  - 当前环境已有同名成熟 skill。
- 判断：**实现方式不错，但没有必要自己养同名平替。**
- 结论：**建议替换。** 你自己的图类型映射如果真的更好，迁成外部数据文件即可。

### `docker-best-practices`

- 优点：覆盖面广，资料量足，能当手册用。
- 问题：
  - 656 行，明显过长。
  - 开头把 Windows 路径、文档策略写成全局规则，污染领域边界。
  - 时效性强，2025 的建议很快就会过时。
  - 更像一篇 Docker best practices 文档，不像一个“调用后马上产生稳定行为”的 skill。
- 判断：**有价值，但应该从“百科式 skill”改成“决策型/评审型 skill”。**
- 建议重构方向：
  - `SKILL.md` 只保留：
    - 触发条件
    - Dockerfile/Compose/K8s 下的选型流程
    - 输出模板
    - 审查 checklist
  - 各类最佳实践、镜像选择、平台差异全部进 `references/`
  - 把“Windows 路径说明”“文档生成偏好”移除出这个 skill
- 结论：**保留并大改。**

### `docs-images-organizer`

- 优点：边界清晰，风险意识正确，规则短。
- 问题：和成熟 skill 直接重叠；本地独占价值不强。
- 判断：**不是坏 skill，但没有必要自己继续养。**
- 结论：**替换。**

### `duckdb`

- 优点：
  - 主题明确。
  - 对 CSV/Parquet/Polars/Pandas 的覆盖很实用。
  - 这是这批里少数仍然有明确独特价值的技能型主题。
- 问题：
  - 411 行，已经偏重。
  - 安装、样例、模式库占比太高。
  - 没有把“什么时候应优先用 DuckDB 而不是 Python/pandas/bash/SQLite”说得更尖锐。
- 判断：**值得保留。**
- 建议重构方向：
  - 在 `SKILL.md` 顶部给出一个决策树：
    - 数据是结构化文件？
    - 需要 join / aggregation / window function？
    - 数据量超出 shell 轻处理范围？
    - 这时优先选 DuckDB。
  - 将大段示例搬到 `references/`
  - 加一个 `scripts/quick_profile.py` 或 `scripts/run_duckdb_sql.py` 之类的确定性脚本
- 结论：**保留并重构。**

### `goreleaser-best-practices`

- 优点：短、边界清晰、结构不错。
- 问题：和成熟 skill 重叠几乎是 1:1。
- 判断：**如果没有你自己的发布流程差异，就没必要本地维护。**
- 结论：**替换。**

### `jq`

- 优点：
  - Pattern Library 其实很有用。
  - 面向实战，不只是语法介绍。
- 问题：
  - 当前环境已有成熟 skill。
  - 475 行，已经接近“整本 jq 便携手册”。
  - `tool-id/tool-binary/generated-at` 暗示它来自另一套生成/分发体系。
- 判断：**你真正的资产是模式库，不是这个同名 skill 壳。**
- 结论：**建议替换 skill 本体。** 若保留，把你的模式库拆到单独参考文件。

### `mermaid-diagrams`

- 优点：参考材料拆得还行，`references/` 组织比很多长 skill 健康。
- 问题：
  - 与 `diagram-picker` 部分重叠。
  - 职责是“Mermaid 专项语法与图类型”，更像 `diagram-picker` 的一个子域。
- 判断：**有一部分价值，但不一定值得独立成 skill。**
- 结论：**建议合并或降级为 reference。**

### `modern-css`

- 优点：
  - 主题本身有价值。
  - 针对“AI 产出过时 CSS”这个痛点是对的。
- 问题：
  - 758 行，过长。
  - frontmatter 很乱，混入注释与外链痕迹。
  - 几乎整份都是知识摘录，不像 skill。
  - `references/` 只有一个 markdown，却没有真正承担“知识下沉”的作用。
- 判断：**方向对，结构不对。**
- 建议重构方向：
  - 改成“现代 CSS 评审与升级决策 skill”
  - `SKILL.md` 保留：
    - 何时触发
    - 先查浏览器支持还是先改代码
    - 输出格式：建议、替换方案、兼容性备注
  - 现代 CSS feature 清单全放 `references/`
  - 如果你已经有 `frontend-design` / `design-taste-frontend` / `web-design-guidelines` 这类技能，`modern-css` 应降为这些技能的专项参考
- 结论：**保留，但必须重构；否则更适合作为 reference 包。**

### `nushell-best-practices`

- 优点：
  - 内容质量不低，说明你对 Nushell 真的做了结构化总结。
  - 主题独特，当前环境没有直接同名成熟替代。
- 问题：
  - 目录名和 `name` 不一致，这是先要修的硬问题。
  - 659 行，过长。
  - 更像“完整 Nushell 编程风格指南”，不是 skill。
- 判断：**有存在价值。**
- 建议重构方向：
  - 先把 `frontmatter.name` 改成与目录一致，或反过来统一目录名
  - `SKILL.md` 只保留：
    - 触发条件
    - 核心原则
    - 常见错误决策树
    - 审查 checklist
  - 详细语法、模式、反模式全移到 `references/`
- 结论：**值得保留并重构。**

### `planning-with-files-zh`

- 优点：
  - 这是整批里最“像你自己的东西”的一个。
  - 有清晰 workflow、模板、脚本。
  - 中文化、本地化都很强。
- 问题：
  - 混入插件/hook 元数据，环境耦合非常重。
  - 安全面更复杂，因为它会不断把文件内容重新注入上下文。
  - 它和当前 agent 自带的计划能力有交叠，不适合无脑自动触发。
- 判断：**有私有价值，但不适合当通用 skill 广泛启用。**
- 建议重构方向：
  - 分成两层：
    - `planning-with-files-zh`：只保留方法论、模板、何时使用
    - 插件/钩子实现：移到插件或单独安装说明，不放在 skill frontmatter
  - 重新收窄触发条件，不要把“超过 5 次工具调用”写得太机械
  - 把安全边界和提示注入风险写得更靠前
- 结论：**保留，但定位成“私有重型 workflow skill”，不要把它当通用基础设施。**

### `react-doctor`

- 优点：极简，知道自己是工具包装。
- 问题：几乎没有本地特异性；当前环境已有成熟 skill。
- 判断：**没有继续自己维护的必要。**
- 结论：**替换。**

### `skill-sk`

- 优点：
  - 这份写得其实不错。
  - 结构、边界、质量检查都比较像一个成熟 overlay。
- 问题：
  - 和成熟 skill 直接重叠。
  - 你自己这次让我用的是 `skill-creator`，而不是这份 `skill-sk`，说明它在你的体系里可能也不是唯一入口。
- 判断：**价值在“中文化与本地偏好”，不在“从零造一个同类 skill”。**
- 结论：**建议替换或极限瘦身成中文 overlay。**

### `slidev-overlay`

- 优点：知道自己只是 overlay，不想包打天下。
- 问题：这类 overlay 很适合依附成熟 `slidev` skill，而不是单独长期维护。
- 判断：**可留可不留，但没必要重。**
- 结论：**建议替换；若保留，只保留你最常问的几个 advanced topic。**

### `taskfile-best-practices`

- 优点：短、清楚、边界明确。
- 问题：与成熟 skill 直接重叠；你自己的私有规则其实更适合进 AGENTS 或 repo docs。
- 判断：**本地维护收益低。**
- 结论：**替换。**

### `typst`

- 优点：组织还算清楚，外部参考文件丰富。
- 问题：当前环境已有成熟 skill；Typst 变化快，长期自己追很累。
- 判断：**没必要本地维护平替。**
- 结论：**替换。**

---

## 建议的处置清单

### 第一批：直接移除或归档

- `ai-tooling-strategy`
- `codex-collaboration`
- `diagram-picker`
- `docs-images-organizer`
- `goreleaser-best-practices`
- `jq`
- `react-doctor`
- `skill-sk`
- `slidev-overlay`
- `taskfile-best-practices`
- `typst`

处理方式建议：

- 如果你担心直接删掉不放心，先移动到 `home/base/tui/AI/skills-archive/`
- 保留一份迁移说明，记录“由哪个成熟 skill 替代”

### 第二批：保留并重构

- `docker-best-practices`
- `duckdb`
- `modern-css`
- `nushell-best-practices`
- `planning-with-files-zh`

### 第三批：合并/降级

- `mermaid-diagrams` -> 合并到 `diagram-picker` 或降级为参考资料

---

## 建议的统一骨架

对你未来还要保留的 skill，建议统一到这个最小结构：

```text
skill-name/
├── SKILL.md
├── references/
│   ├── topic-a.md
│   └── topic-b.md
├── scripts/
│   └── deterministic-helper.py
└── templates/
    └── output-template.md
```

其中：

- `SKILL.md`
  - 只写 trigger
  - 只写 workflow
  - 只写 output format
  - 只写 quality checks
- `references/`
  - 放知识
  - 放语法
  - 放大例子
- `scripts/`
  - 放重复、确定、可验证步骤

### 推荐章节模板

```md
---
name: xxx
description: 何时使用、为什么使用、典型语境
---

# xxx

## 适用范围
## Non-goals
## Inputs
## Outputs
## Workflow
## References
## Quality checks
```

---

## 优先级建议

### P0

- 修正 `nushell-best-practices` 的 `name`/目录不一致
- 清理 `modern-css/references/.DS_Store`
- 清理或归档直接重叠的 skill

### P1

- 重构 `docker-best-practices`
- 重构 `modern-css`
- 重构 `planning-with-files-zh`

### P2

- 重构 `duckdb`
- 重构 `nushell-best-practices`
- 处理 `mermaid-diagrams` 的合并/降级

---

## 最终判断

### 是否有存在价值

**有。**
但不是每一个都值得继续以“独立 skill”形式存在。

真正值得继续维护的，是这类：

- 体现你自己工作方式的 skill
  例如：`planning-with-files-zh`
- 当前环境没有成熟同类，且你自己在这个领域有稳定实践沉淀
  例如：`duckdb`、`nushell-best-practices`
- 能显著约束 AI 在某一细分领域的行为，而不只是提供百科知识
  例如重构后的 `modern-css`

### 是否应该被第三方成熟 skill 替代

**有相当一批应该。**
特别是那些：

- 名称已重合
- 主题高度通用
- 本地没有 repo 私有约束
- 维护成本比收益高

### 是否要大范围调整

**要，但应该是“组合级整理 + 少数重点重构”，不是全量重写。**

最合理的路线不是“把 17 个都修漂亮”，而是：

1. 先删掉一批本来就不该自己维护的平替 skill
2. 再把剩下真正有价值的 4 到 6 个 skill 做成高质量资产

这样你的 skill 集会轻很多，也更像一套“有判断力的个人工具箱”，而不是“收集到哪就塞到哪的提示词仓库”。
