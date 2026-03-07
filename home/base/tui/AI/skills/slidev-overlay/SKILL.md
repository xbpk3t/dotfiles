---
name: slidev-overlay
description: Slidev 进阶 overlay 补充指引，适用于在官方 slidev skill 之外补充选型理由、metadata、语法高亮、speaker notes、具名插槽、Tailwind、主题、Monaco、部署与复用等问题。
---

# Slidev Overlay

## 适用范围

- 仅作为官方 `slidev` skill 的补充，覆盖一组固定的 overlay 问题清单
- 面向 Slidev 选型与进阶用法的结构化回答（why / htu / hto）

## Non-goals

- 不替代官方 `slidev` skill 的基础能力与通用入门说明
- 不扩展到其他演示框架（如 reveal.js）以外的泛化比较

## Inputs

- 用户给出 overlay 问题清单或提到 slidev overlay / 进阶问题
- 明确出现 why / htu / hto 的分组需求

## Outputs（必须）

- 固定结构：`why` / `htu` / `hto` 三段
- 每段输出为条目列表，内容来自 `references/playbook.yaml`
- 必须声明“仅为官方 slidev skill 的补充”

## Workflow（按顺序）

1) 识别输入是否命中 overlay 清单（why/htu/hto）。
2) 读取 `references/playbook.yaml`，按分组筛选对应条目。
3) 生成输出：why/htu/hto 三段 + 补充声明（仅为官方 slidev skill 补充）。
4) 保持条目顺序与原始清单一致，不随意增删。

## References

- `references/playbook.yaml`：overlay 问题清单与分组内容

## Quality checks

- description 是否包含明确触发条件
- scope 是否为“官方 slidev skill 的补充”且 non-goals 写清
- outputs 是否固定为 why/htu/hto 三段
- 输出是否仅来自 playbook 且顺序一致
- 语言是否为中文 + English 术语

## Language

- 中文为主，技术术语使用 English
