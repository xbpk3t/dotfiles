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

### 核心操作拆解（可选，适用于数据结构/算法类定义）

展示该技术最核心的 1–3 个操作流程，用伪代码或步骤列表呈现：

```
read(k):   逐层查找 MemTable → 各级 SSTable，命中即返回
write(k,v): 追加 WAL → 写入 MemTable，MemTable 满后冻结 → 后台刷为 SSTable
compact():  挑选重叠 SSTable → 多路归并去重 → 输出新 SSTable → 淘汰旧文件
```

操作拆解的目的是让读者看到「定义式中的组件如何在运行时协作」，不必覆盖所有 API。

### 边界（可选 1–2 条）

- 这个定义**不**包含 X：因为它是 Y（它与当前定义的对比/从属关系）
- 这个定义**不**包含 Z：它属于另一层抽象/另一机制，不在此定义的范畴内
