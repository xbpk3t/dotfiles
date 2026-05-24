---
description: CodeGraph code knowledge graph usage rules
applyTo: "**"
---
# CodeGraph

## 概述

CodeGraph 是基于 Tree-sitter 的代码知识图谱工具，构建本地 SQLite 索引后通过 MCP 工具暴露给 AI agent。可对任意代码仓库进行结构化搜索、依赖分析、调用链追踪和影响范围评估。

## 初始化

在项目根目录构建索引（一次性操作）：

```bash
codegraph init -i
```

索引构建完成后，`codegraph status` 可查看索引状态。若仓库代码有较大变更，重新运行 `codegraph init -i` 刷新索引。

## MCP 工具

CodeGraph 提供以下 MCP 工具，无需手动批准即可直接调用：

| 工具 | 用途 | 典型场景 |
|------|------|---------|
| `codegraph_search` | 语义搜索代码符号、函数、类型 | 查找某个函数定义、搜索相关实现 |
| `codegraph_explore` | 探索代码库结构和模块关系 | 了解项目整体架构、模块依赖关系 |
| `codegraph_callers` | 查找函数/方法的调用者 | 追踪谁在调用某个函数 |
| `codegraph_impact` | 分析代码变更影响范围 | 修改前评估影响面 |
| `codegraph_files` | 列出项目文件结构 | 快速了解项目目录布局 |
| `codegraph_symbols` | 列出文件中的符号（函数、类、变量） | 查看文件包含哪些定义 |
| `codegraph_outline` | 获取文件结构大纲 | 理解文件内部层次 |
| `codegraph_deps` | 分析符号的依赖关系 | 查看模块/函数导入导出 |
| `codegraph_status` | 查看索引状态和统计信息 | 确认索引是否就绪 |

## 使用原则

- 探索陌生代码库时，先用 `codegraph_explore` 获取全局视角，再用 `codegraph_search` 定位具体实现
- 修改前，用 `codegraph_callers` 和 `codegraph_impact` 评估影响范围
- 索引未构建或过期时，Claude Code 会提示先运行 `codegraph init -i`
- 优先使用 codegraph 工具做结构化代码分析，而非直接 grep/find
