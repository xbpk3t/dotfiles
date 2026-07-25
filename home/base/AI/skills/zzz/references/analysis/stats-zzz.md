---
name: stats-zzz
role: atom
description: 读取 zzz-stats.jsonl，输出子命令频次与降级建议
---

# stats-zzz — zzz 使用统计

读取 `~/.claude/zzz-stats.jsonl`，按子命令分组统计频次，给出排行和建议。

## 输出格式

### 总览
- 统计周期（最早/最晚记录日期）
- 总调用次数
- 去重子命令数

### 频次排行（desc）
| Rank | Subcommand | Count | 占比 | 建议 |
|------|------------|-------|------|------|
| 1 | con | 42 | 35% | keep |
| ... | ... | ... | ... | promote / demote / drop |

### 建议规则
- **Top 5 且 > 10%**：保持为可见入口
- **< 3 次 且 占比 < 1%**：建议设为 dot file 降级
- **0 次**：可考虑删除
- 是否设置 `dot md` 按需手动处理

## 注意

- 文件路径：`~/.claude/zzz-stats.jsonl`
- 格式：每行 JSON `{"sub":"con","ts":"2026-07-25T18:30:00+0800"}`
- 如果文件不存在，说明尚未有任何调用记录
- 若记录超过 1000 行，建议清理旧数据或 rotate
