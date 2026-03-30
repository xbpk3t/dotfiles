---
title: flake Topic Overview
type: readme
status: active
date: 2026-03-30
updated: 2026-03-30
tags: [nix, flake, hosts]
summary: 汇总当前仓库 flake 输出层、hosts 约束与 inventory 边界的长期结论。
---

# flake Topic Overview

本文作为 `docs/flake/` 的总览入口，收敛该 topic 下长期有效的设计约束。带时间线的迁移计划、调研与复盘，继续保留为同目录下按日期命名的 review 文档。

## Scope

- flake 输出层的长期收敛方向
- hosts 与 inventory 的边界设计
- role / host / inventory 之间的职责约束

## Current State

- 当前仓库仍保留现有 `role / host / inventory / deploy` 的整体模型。
- flake 输出层正朝更显式、更低耦合的方向收敛。
- 迁移规划和阶段性分析见 [`2026-03-25-flake-parts-migration.md`](/Users/luck/Desktop/dotfiles/docs/flake/2026-03-25-flake-parts-migration.md)。

## Hosts

### Roles

关于 hosts，最重要的是区分不同 role 的边界。当前主要有三种：

- workstation (`ws`)
- homelab
- vps

### Host Constraints

- `hosts/` 里的配置项不应使用 `lib.mkDefault`，避免 host 层语义变得含糊。
- host 应该表达“这台机器要什么”，而不是“尽量要什么”。
- 默认值和可覆盖策略应放在模块或 inventory 层，不应回灌到 host 声明层。

## Inventory Boundary

参考 `lib/inventory`。

这套设计的目标，是把 host 与 inventory 解耦：

- host 更接近机器角色与配置入口
- inventory 承担节点元数据与身份信息
- 相同 host 结构可以对应不同 node 元数据

这样可以避免把所有差异都硬塞进 host 文件本身，也能让同一类 host 在不同节点上挂接不同 metadata 与 app 组合。

## Decisions

- 输出层要继续收敛，但不应为了迁移而推翻现有整体模型。
- host 是一等配置入口，inventory 是身份与元数据层，两者职责要持续分离。
- 后续若有新的稳定约束，应整理进本文件，而不是重新散落成普通 guide 文件。

## References

- 迁移规划与问题清单：[`2026-03-25-flake-parts-migration.md`](/Users/luck/Desktop/dotfiles/docs/flake/2026-03-25-flake-parts-migration.md)
