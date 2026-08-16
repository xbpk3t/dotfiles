---
frontmatter:
  name: brk
  role: atom
  desc: 技术定义 X = A + B + C；可被 3w3h 硬引用
---

## what

**是什么：**

技术定义：X = A + B + C
给定一个技术/概念，选取其最核心的组件，用 `+` 连接成定义式。

**不是：**

不是长文技术讲解（那是 3w3h 的 hti）
不是架构图（那是 diagram）

## constraint

### must

1. 定义式单行 `+` 连接，禁止先写长文再补公式
2. 核心操作拆解只展示 1–3 个最核心流程，不必覆盖所有 API

### must-not

1. 禁止写伪定义（组件不能对应实际机制）

## output

**format:** md

**template:**

```markdown
## 定义式
`X = A + B + C (+ D…)`

## 分项
| 组件 | 贡献的一句话说明 |
|------|------------------|
| A | ... |

## 核心操作拆解（可选）
```text
read(k):   逐层查找 MemTable → 各级 SSTable，命中即返回
write(k,v): 追加 WAL → 写入 MemTable → 后台刷为 SSTable
compact():  挑选重叠 SSTable → 多路归并去重 → 输出新 SSTable
```

## 边界（可选 1–2 条）
- 这个定义**不**包含 X：因为它是 Y
```

**few-shot:**

```markdown
- LSM = AOF + 稀疏索引
- Redis MSR = PSYNC + RESP buffer
- LRU = linked-list + HashMap
- LevelDB = SkipList（MemTable）+ WAL（顺序写日志）+ SSTable（分层有序文件）+ Compaction（分层合并）
```
