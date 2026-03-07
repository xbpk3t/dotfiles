---
name: goreleaser-best-practices
description: GoReleaser OSS 配置与发布最佳实践，适用于梳理 top-level keys、发布平台支持、CI 触发链路、metadata/hooks 使用与常见坑。
---

# GoReleaser OSS Best Practices

## 适用范围

- 仅覆盖 GoReleaser OSS 能力与配置建议
- 适用于设计/评审 `.goreleaser.yml`、发布流程与平台支持范围
- 输出聚焦 keys 映射、触发链路、必要 secrets 与风险提示

## Non-goals

- 不覆盖 Pro 功能（如 nightlies/announce 等）
- 不输出完整项目级 `goreleaser.yml` 成品模板

## Schema 说明

- 本地整理：`references/schema.yaml`
- 使用方式：先按 feature 识别目标能力，再定位对应 keys

> 以官方文档为准；本地整理用于快速查阅与评估字段影响面。

## Workflow（MUST，按顺序执行）

1) 识别目标：产物类型 + 发布平台 + CI 场景
2) 映射 keys：查 `references/schema.yaml` 与 `references/playbook.yaml`
3) 配置链路：补齐 workflow/secrets/tag 触发策略
4) 校验与发布：先 snapshot/dry-run，再 tag 发布
5) 输出建议：列出关键 keys、触发条件、风险与替代方案

## References

- `references/schema.yaml`：功能 → keys 索引
- `references/playbook.yaml`：what/htu（平台支持 + 配置流程）
- `references/capabilities.yaml`：OSS 支持范围与替代方案

## 输出格式（必须）

- 目标与范围：一句话说明 OSS 范围
- 关键 keys：列出 top-level keys 与理由
- 触发链路：workflow + secrets + tag 触发说明
- 风险/限制：明确 Pro 不在范围 + 可能的替代方案

## Quality checks（必须完成）

- 输出是否明确“仅 OSS”
- 是否给出 keys 映射与触发链路
- 是否引用了 playbook/capabilities 中的内容
- 是否避免了 Pro 功能建议
