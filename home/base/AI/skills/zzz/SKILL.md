---
name: zzz
description: >
  个人 prompt 路由：/zzz <name> 对应 references/**/<name>.yml（name 等于文件名 stem）。
  composite 用 workflow 组织阶段；phase 的 steps 里用 {kind: prompt, name} 串行调度其他 prompt（sub-agent）。
  凡有 dispatch 步的 composite，必须对每个启用的步起 sub-agent（见正文）。
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

### `role: composite` — **workflow 里有 `kind: prompt` dispatch 步就必须用 sub-agent**

**一条铁律：** workflow 里每个 `{kind: prompt, name}` 步，**必须**起一个 **独立 sub-agent** 跑目标 prompt（**串行**：按 workflow/phase/steps 顺序一个一个来）。
**禁止**父 agent 在同一上下文里「心算」跑完 brk / vs 等步骤，也禁止并行 fan-out。

#### 父 agent（编排者）职责

1. 读 composite 的 workflow，找出所有 `{kind: prompt, name}` dispatch 步 + constraint 里的适用性规则
2. 按适用性规则判定每个 dispatch 步**启用**与否（例如：无竞品 → 跳过 vs；**用户未确认** → 跳过 analogy/mapping 等 consent 步）。**未启用 ≠ 忘了跑**：ledger 必须显式 `skipped: <name> — <原因>`，禁止静默省略。
3. 对每个 **启用** 的 dispatch 步，按序**逐个**起 sub-agent：
   - 解析路径：`skx route --dir <skill_dir>/references <step_name>`，再 Read 对应 yml
   - 要求该 sub-agent **只**执行该步 prompt 的 body，且 topic/输入与父任务一致
   - **串行执行**（前一个完成后才起下一个）；后一步可引用前一步已并入的产物
4. **收齐 artifact：** 每个启用的 dispatch 步产出的 artifact，按 output 契约并入最终产物
5. **仅在父 agent 做合并：** 写出 composite 的最终产物（例如 3w3h 的六字段 YAML），**必须以各 step 的 artifact 为准**——不得与之矛盾，也不得默默丢掉已完成的步骤

#### Sub-agent 职责

- 只负责 **一个** dispatch 目标；不要重跑整个 composite
- 返回 **结构化 artifact**（定义表、mermaid+图注、对比表+YAML 等），不要空泛长文
- 若目标文件本身也是 `role: composite`：在 **该 sub-agent 内** 递归套用本规则（嵌套 dispatch → 再起 sub-agent）
  **例外：** 嵌套步是必须共享中间结果的 **纯格式变换** 时，在 **同一 sub-agent 内、主 body 之后串行** 执行（例：`vs` 做完对比后，在同一 agent 内再跑 `table2yml`，保证 YAML 与对比表一致）

#### 硬性约束

- **禁止：** 父 agent 未起对应 sub-agent（也未声明 skipped），却自行产出 breakdown / diagram / vs 等结果
- **跳过：** 父 agent 在 ledger 里明确写 `skipped: <name> — <原因>`，禁止伪造 artifact
- **正文里的 soft 链接**（如 repo 的「可参考 vs」）**不是** dispatch —— **不要**自动 fan-out；除非该 name 是 workflow 里的 `{kind: prompt}` 步且判定启用
- **串行：** dispatch 步按 workflow 顺序逐个跑，禁止并行 fan-out
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

composite 交付时**必须**在末尾输出编排台账，对 workflow 里**每个 dispatch 步（`kind: prompt`）逐一表态**：

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

- 每个 dispatch 步**必须**落在 `enabled` / `skipped` / `merged` 之一，**禁止散文跳过**
- 启用判定看 constraint 的适用性规则；结构必需步（如 brk 的【breakdown】）要么跑 sub-agent、要么 merged 已有 artifact，**绝不静默缺**
- `skipped` 必须有 `reason`；`merged` 写清并入点（如 `hti#breakdown`）

---

## Frontmatter 约定（references 下各 prompt）

```yaml
name: <文件名 stem>      # 必填；必须与文件名 stem 一致
role: atom | composite   # 必填；composite 时必须有 workflow
desc: <短说明>           # 可选；多行用 | 块
```

composite 用 `workflow` 组织阶段；phase 的 `steps` 里可放 dispatch 步（串行起 sub-agent）：

```yaml
workflow:
  - phase: <阶段名>
    steps:
      - 普通操作...                        # string = 内联执行
      - kind: prompt                      # dispatch：串行起 sub-agent 跑目标 prompt
        name: <目标 prompt stem>          # 必填；= references 里存在的 prompt
```

- 适用性规则（何时跑/跳过）放 `constraint.must`；产物并入位置放 `output.template`
- 完整字段/描述见 `prpt.schema.json`

## 配套文件

本 skill 目录下包含以下数据文件（由 `skx` 处理，通常无需手动操作）：

| 文件 | 用途 |
|------|------|
| `references/**/*.yml` | prompt 的 source of truth（schema = docs-alfred `cmd/skx/schema/prpt.schema.json`，`go:embed` 进 skx） |
| `SKILL.md` | 本文件；路由由 `skx route` 执行 |
