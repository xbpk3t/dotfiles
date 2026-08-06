---
name: zzz
description: >
  个人 prompt 路由：/zzz <name> 对应 references/**/<name>.md（name 等于文件名 stem）。
  composite 在 frontmatter 声明 pipeline: [依赖 name]；atom 不声明。
  凡有 pipeline 的 composite，必须对启用的每一步起 sub-agent（见正文）。
  stats 写入 ~/.claude/zzz-stats.json（counter）；3w3h=Teach，recall/mdscc=Test。
  未知 name 列出可用列表，不执行。
---

# /zzz — 个人 Prompt 路由

用户调用 `/zzz <name>` 时，按下列步骤路由到对应模板：

1. 确定 skill 目录（与本 SKILL.md 同级）
2. 执行：`nu <skill_dir>/zzz.nu <skill_dir> <name>`
3. 读取脚本返回的路径（相对 `<skill_dir>`）
4. 读取该文件的 frontmatter + body，并按下方 **role** 规则执行

若脚本返回 `ERROR: unknown` 或 name 无法识别：列出可用 name，不再执行其它逻辑。

---

## Role 执行规则

### `role: atom`

- **只**执行本文件 body（针对用户当前 topic / 输入）
- **不要**自行发明额外 pipeline 步骤
- 按该 atom 要求的输出形态交付（表 / YAML / mermaid 等）

### `role: composite` — **有 `pipeline` 就必须用 sub-agent**

**一条铁律：** frontmatter 里 `pipeline:` 非空时，对每一个 **本轮启用** 的 pipeline name，**必须**各自起一个 **独立 sub-agent** 执行。
**禁止**父 agent 在同一上下文里「心算」跑完 brk / diagram / vs 等步骤。

#### 父 agent（编排者）职责

1. 读 composite 的 frontmatter（`pipeline` 列表）+ body（触发条件、可跳过规则、最终输出格式）
2. 判定本轮哪些 pipeline name **启用**（body 可允许跳过，例如：无运行时链路 → 跳过 `diagram`；无竞品 → 跳过 `vs`；**用户未确认** → 跳过 `analogy`/`mapping` 等 consent 步）。**未启用 ≠ 忘了跑**：必须显式 `skipped: <name> — <原因>`，禁止静默省略。
3. 对每个 **启用** 的 name **单独**起 sub-agent：
   - 解析路径：`nu <skill_dir>/zzz.nu <skill_dir> <step_name>`，再 Read 对应 md
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
- **正文里的 soft 链接**（如 repo 的「可参考 vs」）**不是** pipeline —— **不要**自动 fan-out；除非该 name 在 `pipeline` 中且 body 判定启用
- **路由 / 统计：** 路径解析仍走 `zzz.nu`；sub-agent 使用 **同一** `skill_dir`

#### Step 返回形态（供父 agent 合并）

每个 pipeline sub-agent 结尾应有一段可识别的块，例如：

```text
## artifact
step: <name>
status: ok | skipped
... 该步具体输出 ...
```

---

## Frontmatter 约定（references 下各 prompt）

```yaml
name: <文件名 stem>      # 必填；必须与文件名 stem 一致
role: atom | composite   # 必填
description: <短说明>    # 可选
pipeline:                # 仅 composite 必填且非空
  - <依赖 name>
```

## 配套文件

本 skill 目录下包含以下脚本和数据文件（由主流程自动调用，通常无需手动操作）：

| 文件 | 用途 |
|------|------|
| `zzz.nu` | 路由执行入口；SKILL.md 中通过 `nu <skill_dir>/zzz.nu <skill_dir> <name>` 调用 |
| `gen-aliases.nu` | 别名生成器；扫描 `references/` 下所有 `.md` 的 frontmatter，校验后写 `aliases.json`。在 references 下增删改 prompt 后执行：`cd <skill_dir> && nu gen-aliases.nu` |
| `aliases.json` | 路由映射表；`zzz.nu` 启动时读取，将 `name` 映射到 `references/<path>.md`，由 `gen-aliases.nu` 生成 |
| `strike.nu` | 计数器脚本；strike 流程中追踪当前 turn 数，数据存储于 `/tmp/zzz/strike/` |
