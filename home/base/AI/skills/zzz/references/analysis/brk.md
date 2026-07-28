---
name: brk
role: atom
description: 技术定义 X = A + B + C；可被 3w3h 硬引用
---

# TechBreakdown — 技术定义：X = A + B + C

给定一个技术/概念，选取其最核心的组件，用 `+` 连接成定义式。

**示例：**
- LSM = AOF + 稀疏索引
- Redis MSR = PSYNC + RESP buffer
- LRU = linked-list + HashMap
- LevelDB = SkipList（MemTable）+ WAL（顺序写日志）+ SSTable（分层有序文件）+ Compaction（分层合并）

## 输出

### 定义式

`X = A + B + C (+ D…)`

- 单行 `+` 连接，禁止先写长文再补公式

### 分项

| 组件 | 贡献的一句话说明 |
|------|------------------|
| A | ... |

### 边界（可选 1–2 条）

- 这个定义**不**包含什么
