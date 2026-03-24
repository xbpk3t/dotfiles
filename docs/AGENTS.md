# AGENTS.md

## 作用范围

本文件只约束 `docs/` 目录本身。

## 目录设计

`docs/` 目前只保留两类正文文档：

- `guide/`：长期维护的主题文档、结论性文档、操作指南、参考清单。
- `review/`：按时间沉淀的项目日志、排障记录、迁移过程、调研复盘。

辅助目录：

- `_templates/`：新文档模板。

目录骨架如下：

```text
docs/
  AGENTS.md
  _templates/
  guide/
  review/
```

除非现有 `guide/` / `review/` 的划分已经明显失效，否则不要新增新的顶层分类。

## 主题目录规则

- `guide/` 和 `review/` 下允许继续新增主题子目录。
- 不要把规则写死成“当前只有哪些主题”。
- 只有在确实有利于检索、归档、分组时，才新增主题目录。
- 同一个主题可以同时出现在 `guide/` 和 `review/` 下，但不是强制要求完全对称。

例如：

- `guide/deploy/`
- `guide/system/`
- `guide/nix/`
- `review/k3s/`
- `review/android/`

## 归档规则

- 不使用顶层 `docs/archive/`。
- 归档文档必须留在对应主题目录内部，例如 `guide/deploy/archive/`。
- 任意位于 `archive/` 下的文档，frontmatter 里的 `status` 必须为 `archived`。
- 优先“按主题原地归档”，不要做一个无上下文的统一废弃仓。

## 文件命名

- `guide/` 下文档使用 `kebab-case.md`
- `review/` 下文档使用 `YYYY-MM-DD-kebab-case.md`
- `review/` 文档一旦发布，文件名尽量保持稳定，不要频繁改日期或 slug

## Frontmatter 规范

所有文档至少包含以下字段：

```yaml
---
title: 示例标题
type: guide # 或 review
status: active # draft | active | archived
date: 2026-03-24
updated: 2026-03-24
tags: [nix]
summary: 可选，一句话说明文档内容。
---
```

补充约束：

- `type` 必须与所在目录一致。
- `date` 表示首次成文日期，不要因为后续修订而覆盖。
- `updated` 用于记录最近一次实质性修改。
- `summary` 对长文强烈建议填写；短文可选。

## 文档放置规则

以下内容放到 `guide/`：

- 会长期维护的说明文档
- 已经沉淀下来的稳定结论
- 参考资料清单
- 对仓库某项机制的规范化解释

以下内容放到 `review/`：

- 明显带时间线的记录
- 排障过程
- 迁移日志
- 某次决策窗口内的比较和调研
- 复盘性质文档

如果一篇 `review` 后来演变成长期参考材料，不要无限追加在原文里；应整理出一篇更稳定的 `guide` 版本。

## 编辑原则

- 优先修改已有文档，而不是创建语义重复的新文档。
- 不要机械地把所有内容都塞进某一个主题目录；应按“未来会去哪里找这篇文档”来决定主题。
- 移动文档后，必须检查并修复相对链接。
- 若只是过程记录，不要写成伪装成 guide 的长文。
- 若只是稳定结论，不要混入过多时间顺序的排障噪音。
