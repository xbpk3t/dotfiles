---
name: blog-social-science
description: 用于撰写、改写、结构化或评价中文社科类 Docusaurus/MDX blog。适用于用户想把社会、文化、性别、教育、阶层、劳动、人口、公共舆论、现代性等社科议题写成"像做证明题一样"的文章时。输出应围绕问题、变量、前提、推导链与边界展开，避免站队、群体本质化和空泛大词。
trigger_keywords:
  - 社科写作
  - blog
  - 论证
---

# 社科证明题写作

使用这个 Skill 时，目标是把社科类主题或材料，写成一篇结构清楚、论证可追踪、边界明确的中文 Docusaurus/MDX blog。

## 核心任务

把用户提供的主题、文章、观点或材料，整理成：

```text
问题
→ 变量
→ 前提
→ 推导
→ 边界
```

## 默认工作流

1. 识别真正要解释的问题，而不是停留在表面事件。
2. 提取 3 到 5 个关键变量。
3. 明确 3 到 5 条论证前提。
4. 构造 2 到 4 条主要推导链。
5. 合并推导链，给出有条件的结论。
6. 补充边界、替代解释和可能削弱结论的因素。
7. 输出完整 Docusaurus/MDX Markdown。

## 需要读取的参考文件

* 文章结构：读取 `references/article-structure.md`
* 语言风格：读取 `references/style-rules.md`
* 输出前检查：读取 `references/quality-checklist.md`

## 输出规则

* 默认使用中文。
* 默认输出 Docusaurus/MDX Markdown。
* 使用 `:::info`、`:::tip`、`:::warning`、`:::note` 等 Docusaurus admonition。
* 使用 `text` 代码块展示机制链、推导链或准公式。
* 不要直接站队。
* 不要把群体倾向写成群体本质。
* 不要用大词替代机制。
* 不要只给结论，必须展示推导过程。
* 如果用户只是要求讨论结构或提纲，不要直接生成完整文章。
