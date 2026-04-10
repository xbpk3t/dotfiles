# AGENTS.md

## 作用范围

本文件只约束 `docs/` 目录本身。

## 目录设计

`docs/` 采用“按 topic 分目录”的扁平结构，而不是再区分顶层 `guide/` / `review/`，也不再在 topic 内使用 `review/`、`archive/` 这类子目录。

目录骨架如下：

```text
docs/
  AGENTS.md
  <topic>/
    README.md
    YYYY-MM-DD-<review>.md
    .<internal>.yml
```

其中：

- `docs/<topic>/README.md`：放该主题下当前有效的总览、稳定结论、导航入口。
- `docs/<topic>/YYYY-MM-DD-*.md`：放该主题下按时间沉淀的项目日志、排障记录、迁移过程、调研复盘。
- `docs/<topic>/.*.yml` 等点文件：允许作为该 topic 的隐藏辅助文件存在，但不属于正式文档入口。

不要再新增顶层 `docs/guide/`、`docs/review/`、`docs/archive/` 这类总分类目录，也不要在 topic 内重新引入 `review/`、`archive/` 子目录。

## Topic 目录规则

- 每个 topic 目录名使用简短、稳定、可复用的 slug，例如 `k3s`、`system`、`deploy`、`flake`。
- 是否需要新增 topic，取决于它是否真的提升检索、归档和维护效率。
- 不要把规则写死成“当前只有哪些 topic”。
- 每个 topic 原则上对外只保留一个正式入口文件 `README.md`。
- 除 `README.md`、按日期命名的 review 文档、点文件外，不要继续制造额外层级或额外命名类型。
- `docs/desktop/`、`docs/test/` 这类暂时没有正式文档的 topic 目录可以存在，但后续若沉淀内容，仍应遵守同一结构。

## 文档类型与放置规则

以下内容应整理进 `docs/<topic>/README.md`：

- 当前状态总览
- 会长期维护的说明内容
- 已沉淀下来的稳定结论
- 参考资料清单
- 对仓库某项机制的规范化解释

以下内容应单独写成 `docs/<topic>/YYYY-MM-DD-*.md`：

- 明显带时间线的记录
- 排障过程
- 迁移日志
- 某次决策窗口内的比较和调研
- 复盘性质文档

如果一篇 review 后来演变成长期参考材料，不要无限追加在原文里；应把稳定结论整理回该 topic 的 `README.md`。

## 命名与可见性规则

- 正式总览文件固定为 `docs/<topic>/README.md`。
- 正式 review 文档使用 `docs/<topic>/YYYY-MM-DD-kebab-case.md`。
- 不再新增 `docs/<topic>/foo.md` 这类普通 guide 文件。
- 不把 `.foo.md` 作为正式文档形态；点文件只用于隐藏辅助材料，不用于承载正式文档内容。
- 允许存在 `docs/<topic>/.*.yml`、`docs/<topic>/.*.yaml` 等点文件，用于编辑器配置、特性开关或局部元数据。

## 状态与归档规则

- 不再使用 `archive/` 目录表达归档语义。
- 文档若已废弃但仍需保留上下文，应原地保留，并在 frontmatter 中把 `status` 设为 `archived`。
- `review` 文档一旦发布，文件名尽量保持稳定，不要频繁改日期或 slug。
- 中文标题可以出现在 `title` 中，但文件名本身优先保持 ASCII slug；若已有中文文件名且短期不迁移，不必为形式统一而机械改名。

## Frontmatter 规范

所有正式 Markdown 文档至少包含以下字段：

```yaml
---
title: 示例标题
type: readme # 或 review
status: active # draft | active | archived
isOriginal: true # true | false
date: 2026-03-24
updated: 2026-03-24
tags: [nix]
summary: 可选，一句话说明文档内容。
---
```

补充约束：

- `type` 必须与所在位置一致：
  - `docs/<topic>/README.md` 为 `readme`
  - `docs/<topic>/YYYY-MM-DD-*.md` 为 `review`
- `date` 表示首次成文日期，不要因为后续修订而覆盖。
- `updated` 用于记录最近一次实质性修改。
- `tags` 为必填；至少放主题词，不要留空缺失。
- `summary` 对长文强烈建议填写；短文可选。
- 可保留 `slug`、`unlisted`、`related` 等附加字段，但不要替代基础字段。

## 编辑原则

- 优先修改已有文档，而不是创建语义重复的新文档。
- 不要机械地把所有内容都塞进某一个 topic；应按“未来会去哪里找这篇文档”来决定归属。
- 移动文档后，必须检查并修复相对链接。
- 若只是过程记录，不要写成伪装成 `README.md` 的长文。
- 若只是稳定结论，不要混入过多时间顺序的排障噪音；应收敛整理到 `README.md`。
- 当前仓库正处在从“topic 下混合 guide 文件”进一步收敛到“`README.md` + review 文档”的过程中；判断规范时，以当前约定为准，而不是以历史文件名为准。

## 路径书写规则

- 在 `docs/` 下新增或修改 Markdown 文档时，正文中的文件路径一律使用仓库相对路径。
- 不要在文档正文中写绝对路径，例如 `/Users/luck/Desktop/dotfiles/...`。
- 只有在聊天回复里为了提供可点击文件引用时，才使用绝对路径。
