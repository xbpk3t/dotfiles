# AGENTS.md

## 作用范围

本文件只约束 `docs/` 目录本身。

## 目录设计

`docs/` 采用“按 topic 分目录”的结构，而不是再区分顶层 `guide/` / `review/`。

目录骨架如下：

```text
docs/
  AGENTS.md
  _templates/
  <topic>/
    <guide>.md
    review/
      YYYY-MM-DD-<review>.md
    archive/
      <archived-guide>.md
```

其中：

- `docs/<topic>/`：放该主题下长期维护的正文文档、结论文档、操作指南、参考清单。
- `docs/<topic>/review/`：放该主题下按时间沉淀的项目日志、排障记录、迁移过程、调研复盘。
- `docs/<topic>/archive/`：放该主题下已经废弃但仍需保留上下文的正文文档。
- `docs/_templates/`：新文档模板。

不要再新增顶层 `docs/guide/`、`docs/review/`、`docs/archive/` 这类总分类目录。

## Topic 目录规则

- 每个 topic 目录名使用简短、稳定、可复用的 slug，例如 `k3s`、`system`、`deploy`、`flake`。
- 是否需要新增 topic，取决于它是否真的提升检索、归档和维护效率。
- 不要把规则写死成“当前只有哪些 topic”。
- 同一个 topic 下可以同时存在长期文档与 `review/` 子目录，但不是强制要求两者都存在。
- 除 `review/`、`archive/`、`_templates/` 这类结构性目录外，不要为了局部内容继续制造过深层级。

## 文档类型与放置规则

以下内容直接放到 `docs/<topic>/`：

- 会长期维护的说明文档
- 已沉淀下来的稳定结论
- 参考资料清单
- 对仓库某项机制的规范化解释

以下内容放到 `docs/<topic>/review/`：

- 明显带时间线的记录
- 排障过程
- 迁移日志
- 某次决策窗口内的比较和调研
- 复盘性质文档

如果一篇 review 后来演变成长期参考材料，不要无限追加在原文里；应整理出一篇更稳定的 topic 正文文档。

## 归档规则

- 不使用顶层 `docs/archive/`。
- 归档文档必须留在对应 topic 目录内部，例如 `docs/deploy/archive/old-solution.md`。
- 任意位于 `archive/` 下的文档，frontmatter 里的 `status` 必须为 `archived`。
- 优先“按 topic 原地归档”，不要做一个无上下文的统一废弃仓。

## 文件命名

- `docs/<topic>/` 下正文文档使用 `kebab-case.md`。
- `docs/<topic>/review/` 下 review 文档使用 `YYYY-MM-DD-kebab-case.md`。
- `review` 文档一旦发布，文件名尽量保持稳定，不要频繁改日期或 slug。
- 中文标题可以出现在 `title` 中，但文件名本身优先保持 ASCII slug，避免混合命名。

## Frontmatter 规范

所有正文文档至少包含以下字段：

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

- `type` 必须与所在位置一致：
  - `docs/<topic>/` 下为 `guide`
  - `docs/<topic>/review/` 下为 `review`
- `date` 表示首次成文日期，不要因为后续修订而覆盖。
- `updated` 用于记录最近一次实质性修改。
- `tags` 为必填；至少放主题词，不要留空缺失。
- `summary` 对长文强烈建议填写；短文可选。
- 可保留 `slug`、`unlisted`、`related` 等附加字段，但不要替代基础字段。

## 编辑原则

- 优先修改已有文档，而不是创建语义重复的新文档。
- 不要机械地把所有内容都塞进某一个 topic；应按“未来会去哪里找这篇文档”来决定归属。
- 移动文档后，必须检查并修复相对链接。
- 若只是过程记录，不要写成伪装成长期文档的长文。
- 若只是稳定结论，不要混入过多时间顺序的排障噪音。
- 当前仓库正处在从旧的 `docs/guide/*`、`docs/review/*` 迁移到 topic 结构的过程中；判断规范时，以“当前路径语义”而不是历史路径来源为准。
