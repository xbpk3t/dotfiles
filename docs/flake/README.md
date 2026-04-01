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
- 迁移规划和阶段性分析见 [`2026-03-25-flake-parts-migration.md`](docs/flake/2026-03-25-flake-parts-migration.md)。

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


- `host` 表达角色级配置，也就是一类机器共享的模块组合和默认行为。
- `inventory` 表达节点级元数据，也就是这台实例是谁、在哪、怎么连、带什么
  参数。
- 同一个 `host` 可以被多个 `node` 复用；真正的一机一份差异，放在 `inventory`，不回灌到 `hosts/`。


这样做的目的，是避免把机器身份、网络地址、部署目标和服务参数散落进 host 文件本身。最终 `outputs` 层负责把一个 host role 和一组 inventory nodes 组装成多个实际节点配置。




## Decisions

- 输出层要继续收敛，但不应为了迁移而推翻现有整体模型。
- host 是一等配置入口，inventory 是身份与元数据层，两者职责要持续分离。
- 后续若有新的稳定约束，应整理进本文件，而不是重新散落成普通 guide 文件。
