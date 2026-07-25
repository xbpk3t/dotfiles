---
name: brk
role: atom
description: 技术定义 X = A + B + C；可被 3w3h 硬引用
---

# TechBreakdown — 技术定义：X = A + B + C

能否用几个标识性的技术来定义一下这个技术/概念？

比如说我会说：

- LSM = AOF + 稀疏索引
- Redis MSR = PSYNC + RESP buffer
- LRU = linked-list + HashMap
- LevelDB = SkipList（MemTable）+ WAL（顺序写日志）+ SSTable（分层有序文件）+ Compaction（分层合并）

我需要你用类似的方式来帮我定义一下。

都需要用类似 `+` 的形式来定义。

## 输出

### 定义式

`X = A + B + C (+ D…)`

- 主定义必须是单行 `+` 连接
- 禁止先写长文再补公式

### 分项

| 组件 | 它贡献了什么（一句） |
|------|----------------------|
| A | ... |

### 边界（可选 1–2 条）

- 这个定义**不**包含什么
