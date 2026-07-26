# zzz — personal prompt router

## 动机

这些 prompts 的 source，都是我日常经常输入的内容，以及之前存在
alfred snippets 里的。为了在 export 的 markdown 里不出现大段重复，
把它们做到 skills 里，通过 slash 直接调用。

## 命名与 frontmatter

- `name` 必须等于 **filename stem**（路由名 = 文件名）。
- `role`: `atom` | `composite`（先二分即可）。
- `description`: 短说明。
- `pipeline`: 仅 composite；**name 列表**（S 方案），触发细节写在 body。

```yaml
# atom
---
name: brk
role: atom
description: …
---

# composite
---
name: 3w3h
role: composite
description: …
pipeline:
  - brk
  - vs
---
```

改完 prompt 后在 zzz 目录执行：`nu gen-aliases.nu`（校验 name/role/pipeline 后写 aliases.json）。

## dot file 约定

默认不读取 `.md` 作为路由入口（gen 与 zzz.nu 都不收录 hidden）。
hidden file 仅作为 cross-reference 目标，供其他 prompt 引用。

## cross-reference / pipeline

- composite 的 hard 依赖写在 frontmatter `pipeline`；body 写何时执行 / 可跳过。
- **凡 `pipeline` 非空：默认每个启用步单独 sub-agent，父 agent 只编排与汇总**（见 `SKILL.md`）。
- soft 后续只写在 body（如 repo 文末可参考 vs），不进 pipeline，不自动 fan-out。
- 嵌套 composite：子步仍走 sub-agent；纯格式变换（如 vs→table2yml）可在同一 vs-agent 内串跑以免丢表。
- 避免 loop hell；gen 会做简单环检测。

## 坐标系（Teach / Test）

- **3w3h** = Teach / 说明切（讲清楚）；YAML 项强制 `【kw】问题？ # 答案`，文末给 `## next`。
- **mdscc** = Test / 闭卷骨架（meta/derive/sol/cost/case）；**不并进** 3w3h。
- **recall** = composite：出题批改 + gap 收敛；`pipeline: [analogy, mapping]` 仅用户确认后 sub-agent。

## 统计

- 路由命中写入 `~/.claude/zzz-stats.json`（JSON counter：`count` / `last_ts` / `target`）。
- 旧 `zzz-stats.jsonl` **忽略**（不读不迁）；需要时手动删除。
- 看频次：`/zzz stats-zzz`。

## 维护

- 定期调用 `stats-zzz` 看频次，低频可 hidden 或删。
- 保证 prompts 质量与使用频率。
- 改完 prompt 后：`nu gen-aliases.nu`。
