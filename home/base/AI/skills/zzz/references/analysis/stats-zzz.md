---
name: stats-zzz
role: atom
description: 读取 zzz-stats.json，输出子命令频次与降级建议
---

# stats-zzz — zzz 使用统计

读取 `~/.claude/zzz-stats.json`（**JSON counter**，按 sub 直接改 `count`），给出排行和建议。

## 存储形态

路径：`~/.claude/zzz-stats.json`

```json
{
  "3w3h": { "count": 12, "last_ts": "2026-07-26T12:00:00+0800", "target": "analysis/3w3h" },
  "recall": { "count": 3, "last_ts": "…", "target": "analysis/recall" }
}
```

- 每次 `/zzz <name>` 路由成功：`count += 1`，更新 `last_ts` / `target`
- **不读**旧的 `~/.claude/zzz-stats.jsonl`（若仍存在可手动删或留档；stats 与路由均忽略它）
- 文件不存在：说明尚未有任何新格式调用记录 → 总次数 0

## 输出格式

### 总览

- 统计周期（各 sub 的 `last_ts` 最早/最晚，若有）
- 总调用次数（sum of count）
- 去重子命令数

### 频次排行（desc）

| Rank | Subcommand | Count | 占比 | last_ts | 建议 |
|------|------------|------:|------|---------|------|
| 1 | con | 42 | 35% | … | keep |
| … | … | … | … | … | promote / demote / drop |

### 建议规则

- **Top 5 且 > 10%**：保持为可见入口
- **count < 3 且 占比 < 1%**：建议设为 dot file 降级
- **0 次**（aliases 有但 json 无键）：可考虑删除或观察
- 是否设置 `dot md` 按需手动处理

## 注意

- 由 `zzz.nu` 的 `log-hit` 写入；本 prompt 只负责读与建议
- 需要重置统计时：删除或清空 `~/.claude/zzz-stats.json` 即可
