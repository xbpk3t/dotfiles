# zzz — personal prompt router

## 动机

这些 prompts 的 source，都是我日常经常输入的内容，以及之前存在
alfred snippets 里的。为了在 export 的 markdown 里不出现大段重复，
把它们做到 skills 里，通过 slash 直接调用。

## 命名与 frontmatter

- `name` 必须等于 **filename stem**（路由名 = 文件名）。
- `role`: `atom` | `composite`（先二分即可）。
- `desc`: 短说明（多行用 `|` 块）。
- composite 用 `workflow` 组织阶段；phase 的 `steps` 里用 `{kind: prompt, name}` 串行调度其他 prompt（sub-agent）。适用性/并入规则在 constraint 与 output。

```yaml
# atom
---
name: brk
role: atom
desc: …
---

# composite
---
name: 3w3h
role: composite
desc: …
workflow:
  - phase: Pipeline 合并
    steps:
      - 普通操作...
      - kind: prompt
        name: brk
      - kind: prompt
        name: vs
---
```

改完 prompt 后无需额外命令：`skx route`/`skx check`/`skx graph` 直接读 `references/**/*.yml`。

## dot file 约定

`skx route` 跳过 hidden（dot-prefixed）的 `.yml`，如 `.TableCate.yml`。
hidden 仅作为 cross-reference 目标供其他 prompt 引用，不直接可路由。

## cross-reference / dispatch

- composite 的 dispatch 步声明在 workflow 的 steps（`{kind: prompt, name}`）；适用性规则在 constraint，产物并入位置在 output。
- **凡有 dispatch 步：默认每个启用步单独 sub-agent（串行），父 agent 只编排与汇总**（见 `SKILL.md`）。
- soft 后续只写在 body（如 repo 文末可参考 vs），不写成 dispatch 步，不自动 fan-out。
- 嵌套 composite：子步仍走 sub-agent；纯格式变换（如 vs→table2yml）可在同一 vs-agent 内串跑以免丢表。
- 避免 loop hell；`skx graph` 做环检测。

## 坐标系（Teach / Test）

- **3w3h** = Teach / 说明切（讲清楚）；YAML 项强制 `【kw】问题？ # 答案`，文末给 `## next`。
- **mdscc** = Test / 闭卷骨架（meta/derive/sol/cost/case）；**不并进** 3w3h。
- **recall** = composite：出题批改 + gap 收敛；dispatch = [analogy, mapping]（kind: prompt），仅用户确认后 sub-agent。

## 统计

- 路由命中由 `skx route` 自动写入 `~/.claude/zzz-stats.json`（array：`name` / `count` / `last_ts` / `target`）。
- 旧 `zzz-stats.jsonl`（及旧 KV 结构）**忽略**（不读不迁）；需要时手动删除。
- 看频次/降级建议：`skx stats`。

## 维护

- 定期跑 `skx stats` 看频次，低频可 hidden 或删。
- 保证 prompts 质量与使用频率。
- 改完 prompt 后：`skx check`（默认校验部署后的 `~/.claude/skills/zzz/references`）。
  改源码未 rebuild 前用 `skx check --dir <repo>/home/base/AI/skills/zzz`，或设 `export SKX_DIR=<repo 路径>` 免敲。
