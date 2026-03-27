---
title: 关于 runtime owner、microvm 与 Incus 的一次补充判断
type: review
status: active
date: 2026-03-25
updated: 2026-03-25
tags:
  - nixos
  - docker
  - incus
  - microvm
  - k3s
summary: 复盘在 Docker 管理方案之外继续评估 microvm.nix 与 Incus 后得到的结论：对当前仓库来说，runtime owner 仍应交给运行时本身，而不是由 Nix 或 systemd 直接托管应用生命周期。
---

# 关于 runtime owner、microvm 与 Incus 的一次补充判断

这次补充评估，主要是为了回答一个问题：

在已经确认 `Nix 不应该直接托管应用 lifecycle` 之后，`microvm.nix` 或 `NixOS + Incus` 是否会成为更好的主线方案？

结论先说：

- `microvm.nix` 不适合当前仓库作为主线方案。
- `Incus` 比 `microvm.nix` 更值得研究，但它也不是完全声明式方案。
- 当前仓库的主线仍然应该是：
  - `k3s` 负责平台化、集群化、GitOps 化的应用；
  - `Compose + Taskfile` 负责普通 self-hosted 应用；
  - `Incus` 只适合作为少数特殊 workload 的补充工具。

## **_我对`应用管理工具`的偏好_**

这次讨论里，最值得明确记录的，不是某个具体工具，而是我对“应用管理”这件事的偏好。

我已经基本确认：

- 应用 lifecycle 的 owner 应该是运行时本身，而不是 Nix。
- 我不希望 `systemd` 或 `NixOS module` 直接成为这些应用的主控制面。
- 我更接受“宿主机声明式，应用运行时自管”的分层，而不是让 Nix 去包裹另一个已经自带 lifecycle 的系统。

这也是为什么 `microvm.nix` 对当前仓库吸引力有限。

`microvm.nix` 的真正价值在于：把轻量 VM 以 Nix 友好的方式纳入系统设计。但它更适合 `guest OS + NixOS/systemd` 这一套思路。如果我并不想让 `systemd/Nix` 去管理应用，那么它即使提供了更强隔离，也不是我当前最想要的能力。

换句话说，这次评估再次确认的不是“哪个工具更高级”，而是：

> 我更关心 owner 是否清晰，而不是所有东西是否都能被 Nix 化。

## 为什么 `microvm.nix` 不是当前主线答案

`microvm.nix` 的核心价值是让“轻量 VM”成为 Nix 中的一等公民。它提供的是更强的隔离边界，而不是更简单的应用运维模型。

但对当前仓库来说，它的问题在于：

1. 它本质上仍然更适合 `guest OS + NixOS/systemd` 这一套治理思路。
2. 而我已经确认自己不希望由 `systemd/Nix` 成为应用 lifecycle 的直接 owner。
3. 如果在 microVM 里继续跑 Docker/Compose，那么之前的核心矛盾并没有消失，只是从宿主机转移到了 guest 里。

因此，`microvm.nix` 更像是未来可能有用的隔离技术，而不是当前仓库缺失的主线能力。

## 为什么 `Incus` 比 `microvm.nix` 更有意思

`Incus` 的价值不在于“完全声明式”，而在于它可以成为一个明确的 runtime owner。

如果边界定义为：

- `NixOS` 只负责宿主机基线；
- `Incus` 负责 instance lifecycle；
- instance 内部再由各自运行时管理应用；

那么它可以避免之前 Docker 方案里最核心的问题：让 Nix 和应用运行时争夺 owner。

换句话说，`Incus` 成立的前提不是“更 declarative”，而是“owner 更清晰”。

## 但 `Incus` 仍然不是完全声明式方案

这一点需要明确记录：

- `Incus` 有自己的控制面和状态数据库；
- 它不是像 `NixOS` 或 `k3s` 那样天然以文件作为唯一真相源；
- 它更像 `Docker`、`Dokploy` 这类 runtime/control plane，只是抽象层级更底。

所以如果目标是“完全声明式”，`Incus` 依然不是最终答案。

## 当前仓库更合适的运行时分层

结合当前仓库现状，更合理的划分是：

1. `k3s`

用于平台化、长期运行、已经适合 GitOps、Helm、operator 的应用。

2. `Compose + Taskfile`

用于普通 self-hosted 应用，保持低心智负担和直接运维体验。

3. `Incus`

只用于少数需要“完整实例语义”或更强隔离边界的特殊 workload。

## 这次补充判断真正确认了什么

这次评估并没有得出“应该迁移到 microvm”或“应该全面切到 Incus”的结论。

真正被再次确认的是：

> 对当前仓库来说，最重要的不是选择一个更酷的 runtime，而是先明确 runtime owner。

只要 owner 不清楚，就算把 Docker 换成 microVM、LXC 或 Incus，也仍然会重复同一类架构问题。

而一旦 owner 清楚，很多方案其实都可以成立；区别只在于复杂度、隔离强度与适用场景。
