---
frontmatter:
  name: tools-eval
  role: atom
  desc: 工具形态决策器——判断某工具对我是否有效、该以什么形态存在，输出 keep/drop/replace + 形态归属
---

## what

**是什么：**

对一个候选工具做形态决策：①对我有没有用（keep/drop/replace）②该以什么形态存在（网页/CLI/devtools/自建）。
只做"对我值不值得 + 放哪"的裁决，不做工具好坏的泛化评价。

**不是：**

不是工具评测（那是 explore）
不是竞品对比（那是 vs）
不是技术拆解（那是 brk）

## gate

| 问题 | 失败则 |
| --- | --- |
| 这是"新增候选"还是"复盘已有"？ | 复盘已有收藏先走清理上下文；本 skill 面向新增前判断 |
| 我是否真的高频需要它？ | 频率 < 一月一次 → 直接 drop，进不了下一步 |
## constraint

### must

1. 必须给出 verdict + form 两个字段，不得只答"有用/没用"
2. replace 必须给出具体 CLI 命令，不得只说"有 CLI 替代"
3. keep 必须有护城河依据，禁止"感觉还不错"作为理由
4. CLI 优先：未主动搜过 CLI 就下 replace/keep 结论的，判为未完成评估
5. drop 优先于 keep：证据不足时默认 drop，理由写"无证据支持保留"

### must-not

1. 禁止下结论后不改（先验可推翻：用户给反证则无条件更新裁决）

## workflow

### 评估流程（四问，按序）

1. 1、现有栈重复吗：查 data/gh 是否已有同 topic/能力（gh search / data-cli check）；已有 → drop（并入已有）
2. 2、有 CLI/本地上位替代吗：主动找 CLI（yq/jq/openssl/git/pd 栈）；找到 → replace 并给出具体命令；先验可推翻
3. 3、网页壳层真不可替代吗：只有可视化交互 / 链接共享 / 品牌权威数据 / 无 CLI 等效运行时 之一成立才算护城河
4. 4、归属哪个形态：CLI（无状态确定性）/ 网页（交互可视化，默认不收藏=FOMO）/ devtools（生成类+可逆变换+高频+CLI 记忆成本高）/ drop

### 判据修正

1. 进 devtools 看取用成本差（CLI 是否短到肌肉记忆），不是看高频

## output

**format:** table

**struct:**

- key: verdict
  val: <keep | drop | replace | 并入已有topic>
- key: form
  val: 网页 | CLI | devtools | 自建 | 无
- key: frequency
  val: 高频 | 低频 | 未知（FOMO 信号）
- key: cli_alternative
  val: <具体命令> 或 无
- key: moat
  val: <网页护城河> 或 无
- key: overlap
  val: <data/gh 已存在项> 或 无

## hint

| if | then |
| --- | --- |
| replace → CLI | 装进 dotfiles / Taskfile；需要时包一层 nu 或 alias |
| keep → devtools | 进 cmd/devtools 的 toolsIndex（只收生成类+可逆变换、输出单行） |
| keep → 网页 | 进书签（若高频）或仅记 URL（低频但想得起来）；不默认收藏 |
| drop | 不占书签位，需要时 Google 第一屏 |
| 并入已有 topic | 在 data/gh 对应 topic 补 record/score |
