---
title: kernel Topic Overview
type: readme
status: active
date: 2026-03-30
updated: 2026-03-30
tags: [kernel, nixos, vps]
summary: 汇总当前仓库中 VPS 内核参数调优与内核安全方向的长期结论。
---

# kernel Topic Overview

本文作为 `docs/kernel/` 的总览入口，收敛该 topic 下长期有效的内核相关结论。带时间线的调优过程、实验记录和阶段性方案，继续保留为同目录下按日期命名的 review 文档。

## Scope

- VPS 场景下的内核与 sysctl 调优
- 内核安全相关的整理方向
- inventory、模块入口与动态生成逻辑的边界

## Current State

- 当前内核调优主线是 VPS 网络与 sysctl 参数动态生成。
- 相关实现集中在：
  - `lib/vps-sysctl.nix`
  - `modules/nixos/vps/sysctl.nix`
- 现有详细方案记录见 [`2026-01-26-vps-kernel-sysctl.md`](/Users/luck/Desktop/dotfiles/docs/kernel/2026-01-26-vps-kernel-sysctl.md)。

## VPS Kernel Security

当前内核安全部分仍处于草案阶段，但范围已经明确：

- 梳理 VPS 场景下值得长期保留的内核安全参数
- 区分“网络/性能调优”和“安全基线”两类配置
- 避免把一次性实验配置直接沉淀成长期默认值

后续如果这部分形成稳定结论，应整理回本文件，而不是单独新增普通 guide 文件。

## Decisions

- 内核 topic 下的长期结论统一收敛到 `README.md`。
- 具体调优过程、参数推导与阶段性方案保留在 dated review 文档中。
- 安全方向尚未收敛时，可以先以草案状态继续在 dated review 中演进。

## References

- VPS 内核 / sysctl 调优方案：[`2026-01-26-vps-kernel-sysctl.md`](/Users/luck/Desktop/dotfiles/docs/kernel/2026-01-26-vps-kernel-sysctl.md)
