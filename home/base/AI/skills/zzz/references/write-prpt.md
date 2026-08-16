---
frontmatter:
  name: write-prpt
  role: atom
  desc: 编写/重构 prompt skill；产出符合 prpt.yml 全量 schema 的完整 YAML；先对齐信息再开工
  is-save: true
---

## what

**是什么：**

根据用户需求，编写或重构一个 prompt，产出符合 prpt.yml（zzz 全量 key 模板）的完整 YAML 文件，可直接放入 references/ 作为 source of truth。
以 prpt.yml 为唯一准绳，不 inline YAML 模板。

**不是：**

不是优化已有 prompt 的性能（那是 SkillOpt / skill-creator）
不是编写 skill harness（zzz.nu、gen-aliases.nu 等）
不是项目管理（那是 issue 的事）

## constraint

### must

1. 链式调用其它 prpt 时必须引用该 prpt 的文件本身（相对链接），按完整格式执行；禁止只转述规则/只提名字/把规则抄进本文件
2. 产出必须符合 prpt.yml 的 schema（全量 key）

### must-not

1. 禁止不显式输出 Gate A 判断就开工
2. 禁止 inline YAML 模板（引用 prpt.yml 文件）

## workflow

### Gate A 初判（该不该写）

1. 强制显式输出：无论信息是否充分，回答里必须显式写出 Gate A 判断（该写/不该写/需 drill + 依据），禁止默默判断后默认执行
2. 输出格式：##
## Gate A 判断
verdict: 该写 | 不该写 | 需 drill
依据: <一句话理由>

3. 判断依据（该不该写 = 值不值得 skill 化）：固定工作流/格式转换/决策辅助 → 该写；主观创作 → 边缘；一次性/临时 → 不该写
4. 初判分支：信息已足+明显不该写 → 直接挡；信息已足+该写 → 跳终判确认；信息不足 → 进 Gate 1 drill

### Gate 1 信息量（不足 → drill me）

**gate:** 初判 = 需 drill

1. 不存在"有了名字+目标就直接开工"的 case；信息不够直接 drill me
2. 信息充分判据（至少 3 条）：目标用途 / 触发场景 / 输出形态 / 边界 / 受众
3. drill me 规则（内联）：禁止开放问题，必须转选择题（2-3 选项），最多 3 个，可推断不提问

### Gate A 终判（最终裁决）

**gate:** Gate 1 drill 完成 或 信息已足

1. 显式输出终判：不该写 → 停（说明理由）；该写 → 进入写作
2. 信息充足时初判"该写"→ 直接跳终判确认，不能跳过终判

### 执行写作

1. 先 Read prpt.yml（zzz 根目录 `../prpt.yml`，与 references/ 同级）——它为唯一准绳/全量 key 模板
2. 按 prpt.yml 的全量 key schema 组织产出 YAML，只保留实际需要的 key
3. 只使用 prpt.yml 里的 key；不 inline 模板
4. 语言适配（Gate 3）：默认中文；用户明确指定则用对应语言

### 输出与落盘

1. 输出完整 YAML（对话中呈现）
2. 不自动落盘：默认只在对话输出，询问用户是否写入
3. 落盘路径（用户确认后）：$HOME/.claude/skills/zzz/references/（测试）；测完整合回 dotfiles

## hint

| if | then |
| --- | --- |
| 产出完成 | nu gen-aliases.nu（在 dotfiles 侧跑；active 需 rebuild） |
| 用户确认落盘到 references | 写入 $HOME/.claude/skills/zzz/references/ 并测路由 |
