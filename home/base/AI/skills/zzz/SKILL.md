---
name: zzz
description: >
  个人 prompt 路由：/zzz <name> 对应 references/**/<name>.yml（name 等于文件名 stem）。
  composite 在 frontmatter 声明 pl-serial/pl-parallel（依赖 name 列表）；atom 不声明。
  凡有 pl-* 依赖的 composite，必须对启用的每一步起 sub-agent（见正文）。
  stats 写入 ~/.claude/zzz-stats.json（counter）；3w3h=Teach，recall/mdscc=Test。
  未知 name 列出可用列表，不执行。
---

# /zzz — 个人 Prompt 路由

用户调用 `/zzz <name>` 时，按下列步骤路由到对应模板：

1. 确定 skill 目录（`<skill_dir>`）
2. 执行：`skx route --dir <skill_dir>/references <name>`
3. 读取脚本返回的 .yml 绝对路径，Read 该文件
4. 读取该文件的 frontmatter + body，并按下方 **role** 规则执行

若 `skx route` 返回 `ERROR: unknown` 或 name 无法识别：列出可用 name，不再执行其它逻辑。

统计（counter）由 `skx route` 自动写入 `~/.claude/zzz-stats.json`（array 结构）；查看排行/降级建议用 `skx stats`。

---

## Role 执行规则

### `role: atom`

- **只**执行本文件 body（针对用户当前 topic / 输入）
- **不要**自行发明额外 pipeline 步骤
- 按该 atom 要求的输出形态交付（表 / YAML / mermaid 等）

### `role: composite` — **有 `pl-serial`/`pl-parallel` 就必须用 sub-agent**

**一条铁律：** frontmatter 里 `pl-serial`/`pl-parallel` 非空时，对每一个 **本轮启用** 的依赖 name，**必须**各自起一个 **独立 sub-agent** 执行。
**禁止**父 agent 在同一上下文里「心算」跑完 brk / vs 等步骤。

#### 父 agent（编排者）职责

1. 读 composite 的 frontmatter（`pl-serial`/`pl-parallel` 列表）+ body（触发条件、可跳过规则、最终输出格式）
2. 判定本轮哪些依赖 name **启用**（body 可允许跳过，例如：无竞品 → 跳过 `vs`；**用户未确认** → 跳过 `analogy`/`mapping` 等 consent 步）。**未启用 ≠ 忘了跑**：必须显式 `skipped: <name> — <原因>`，禁止静默省略。
3. 对每个 **启用** 的 name **单独**起 sub-agent：
   - 解析路径：`skx route --dir <skill_dir>/references <step_name>`，再 Read 对应 yml
   - 要求该 sub-agent **只**执行该步 prompt 的 body，且 topic/输入与父任务一致
   - 步骤之间无数据依赖时，**优先并行** fan-out
4. **汇合（barrier）：** 等全部 step agent 结束，收集各自 artifact
5. **仅在父 agent 做合并：** 写出 composite 的最终产物（例如 3w3h 的六字段 YAML），**必须以各 step 的 artifact 为准**——不得与之矛盾，也不得默默丢掉已完成的步骤

#### Sub-agent 职责

- 只负责 **一个** step name；不要重跑整个 composite
- 返回 **结构化 artifact**（定义表、mermaid+图注、对比表+YAML 等），不要空泛长文
- 若该 step 文件本身也是 `role: composite`：在 **该 sub-agent 内** 递归套用本规则（嵌套 pipeline → 再起 sub-agent）
  **例外：** 嵌套步是必须共享中间结果的 **纯格式变换** 时，在 **同一 sub-agent 内、主 body 之后串行** 执行（例：`vs` 做完对比后，在同一 agent 内再跑 `table2yml`，保证 YAML 与对比表一致）

#### 硬性约束

- **禁止：** 父 agent 未起对应 sub-agent（也未声明 skipped），却自行产出 breakdown / diagram / vs 等结果
- **跳过：** 父 agent 明确写 `skipped: <name> — <原因>`，禁止伪造 artifact
- **正文里的 soft 链接**（如 repo 的「可参考 vs」）**不是** pipeline —— **不要**自动 fan-out；除非该 name 在 `pl-serial`/`pl-parallel` 中且 body 判定启用
- **路由 / 统计：** 路径解析走 `skx route`（写入 counter）；sub-agent 使用 **同一** `skill_dir`

#### Step 返回形态（供父 agent 合并）

每个 pipeline sub-agent 结尾应有一段可识别的块，例如：

```text
## artifact
step: <name>
status: ok | skipped
... 该步具体输出 ...
```

#### 编排台账（pipeline ledger）— composite 强制

composite 交付时**必须**在末尾输出编排台账，对 frontmatter **每个 pl-\* 步逐一表态**：

```text
## pipeline ledger
enabled:
  - brk
skipped:
  - name: vs
    reason: 无竞品
  - name: diagram
    reason: 纯概念，无运行时链路
merged:
  - brk → hti#breakdown
```

- 每个 pl-\* 步**必须**落在 `enabled` / `skipped` / `merged` 之一，**禁止散文跳过**
- 触发判定看 `pipeline` section 的 `when`；`required: true` 的步要么跑 sub-agent、要么 merged 已有 artifact，**绝不静默缺**
- `skipped` 必须有 `reason`；`merged` 写清并入点（如 `hti#breakdown`）

---

## Frontmatter 约定（references 下各 prompt）

```yaml
name: <文件名 stem>      # 必填；必须与文件名 stem 一致
role: atom | composite   # 必填；composite 时 pl-serial/pl-parallel 至少一个非空
desc: <短说明>           # 可选；多行用 | 块
pl-parallel:             # 仅 composite；并行依赖 name 列表
  - <依赖 name>
pl-serial:               # 仅 composite；串行依赖 name 列表
  - <依赖 name>
```

composite 还需在顶层加 `pipeline:` section，声明每个 pl-\* 步的触发（when）/合并（merge）/是否必跑（required），见 `prpt.schema.json` 描述。

## 配套文件

本 skill 目录下包含以下数据文件（由 `skx` 处理，通常无需手动操作）：

| 文件 | 用途 |
|------|------|
| `references/**/*.yml` | prompt 的 source of truth（schema = docs-alfred `cmd/skx/schema/prpt.schema.json`，`go:embed` 进 skx） |
| `SKILL.md` | 本文件；路由由 `skx route` 执行 |
