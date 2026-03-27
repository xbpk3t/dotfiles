---
title: hosts 设计约束
type: guide
status: active
date: 2026-03-25
updated: 2026-03-25
tags:
  - nix
  - flake
  - hosts
summary: 说明 inventory 中 hosts 的角色划分，以及 host 配置应遵守的约束。
---

# hosts

## roles

关于 hosts，最重要的就是区分清楚不同的roles

这里分为三种

- workstation (ws)
- homelab
- vps

## 要求

- hosts里的配置项不应该有任何 `lib.mkDefault`，以保证其中配置没有歧义。否则会很容易出现。
