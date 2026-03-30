---
title: Remove nh And Clarify Darwin GC Owner
type: review
status: done
date: 2026-03-28
updated: 2026-03-28
tags: [nix, darwin, determinate-nix, gc, nh]
summary: 移除 nh，并把 Darwin 侧的 GC owner 明确收敛到 Determinate Nixd。
---


## TLDR

这次处理的目标很小，核心是把 `nh` 从当前工作流里下线，并把 Darwin 侧的 GC 责任边界说清楚。

问题核心还是出自于 darwin 上（用nh配置）的GC一直没生效

之所以用nh，就是之前希望可以把 darwin和nixos的相关操作，都收束到 `nh`，但是现在看来没什么必要。NixOS上最好用的方案，肯定是 `nixos-cli` 了。而 darwin上，我使用的 Determinate-Nix 本身也提供了全套的更适用于 darwin 的方案。所以最终决定移除掉 nh，都选择各自的原生方案。



## 结论

- 已移除 `nh` 的 Home Manager 配置。
- 已移除 Darwin 上依赖 `nh clean all` 的 `launchd` task。
- NixOS 侧恢复使用原生 `nix.gc`。
- Darwin 侧显式声明由 `Determinate Nixd` 负责 automatic GC，而不是继续依赖 `nh` 或手搓 `launchd`。

## 原因

- 对当前仓库来说，`nh` 已经没有不可替代职责。
- 之前的 Darwin `nh-clean-all` 实际上已经失效，导致“看起来配了 GC，实际上没正常跑”。
- 当前 Darwin 本来就由 `Determinate Nix` 接管 Nix daemon，因此 GC 也应由同一个 owner 负责，避免多套机制并存。

## 备注

- 这次不追求扩展能力，只做职责收敛和行为显式化。
- 后续如果排查 Darwin 垃圾回收，优先看 `Determinate Nixd` 的配置与日志，不再看 `nh`。
