---
title: exploring-comin
type: review
status: active
date: 2026-03-25
updated: 2026-03-25
tags:
  - nix
  - comin
  - deploy-rs
  - deploy
  - gitops
summary: 评估 comin 作为 pull-first 主机部署方案时，对当前仓库的吸引力、风险和不适配点。
---

# exploring-comin

```markdown
## nlewo/comin (3/5)

URL: <https://github.com/nlewo/comin>

具体原因：

- 你的仓库已经在 Kubernetes 层采用了明显的 GitOps 思路：[`homelab-flux-sync.sh`](/Users/luck/Desktop/dotfiles/homelab-flux-sync.sh) 和 `manifests/` + Flux 已经证明你接受“Git 为事实源”。
- 对 NixOS 主机层，如果你后续也想走“目标机自拉取、自应用”的 pull 模式，`comin` 在理念上是能接上的。
- 但你当前**明确的主机部署主链路**是 `deploy-rs`，而且仓库里还有从 Colmena 迁移到 `deploy-rs` 的文档，这说明你已经做过部署范式收敛，不宜轻易再分叉。
- 因此它不是没用，而是**只在你明确想把主机层也改成 GitOps pull 模式时才有用**；否则会和现有 `deploy-rs` 主链路形成双轨。
```

## Context

[`nlewo/comin`](https://github.com/nlewo/comin) 的吸引力很直接：

- 它走的是 `Git push -> target pulls -> target deploys` 的 pull-first 模型。
- 它不仅支持 `NixOS`，也支持 `nix-darwin`。
- 对已经接受 Kubernetes/Flux GitOps 思路的仓库来说，主机层看起来也可以继续往 Git 驱动靠拢。

这和当前仓库的现状形成了一个很自然的对比：

- Kubernetes workload 层已经是明显的 GitOps/pull 模式，见 [`homelab-flux-sync.sh`](/Users/luck/Desktop/dotfiles/homelab-flux-sync.sh) 与 `manifests/`。
- 主机层已经收敛到 `deploy-rs`，而且是有意为之，不是临时拼出来的，见 [`docs/deploy/deploy-rs-migration.md`](/Users/luck/Desktop/dotfiles/docs/deploy/deploy-rs-migration.md)。
- `deploy-rs` 已经深度接入 flake outputs、checks、inventory adapter 和 Taskfile，见 [`outputs/default.nix`](/Users/luck/Desktop/dotfiles/outputs/default.nix)、[`lib/inventory/utils.nix`](/Users/luck/Desktop/dotfiles/lib/inventory/utils.nix)、[`/.taskfile/nix/Taskfile.deploy.yml`](/Users/luck/Desktop/dotfiles/.taskfile/nix/Taskfile.deploy.yml)。

所以问题不是 “comin 能不能用”，而是：

> 当前仓库有没有必要把主机部署主链路，从 `push-first` 改成 `pull-first`。

## What Looked Attractive

`comin` 对当前仓库最有吸引力的点主要有这几个：

- 不再依赖固定控制机主动 SSH 推送，目标机自己轮询 Git 并收敛。
- 对跨 NAT、间歇在线、分散节点更友好，只要求目标机能出网。
- 更接近 “主机层 GitOps”，部署入口可以从命令行操作收敛到 Git 提交。
- 对 NixOS / nix-darwin 都可覆盖，不是只适用于 Linux 机器。

换句话说，`comin` 吸引人的地方，不在于 “它也能部署 darwin”，而在于：

> 它把“谁触发部署”这件事，从控制机挪到了目标机自身。

## Decisions

### 1. `comin` 可以做跨 profile，但这不等于它自然适合当前主链路

这里需要纠正一个容易说得过头的判断：

- `comin` 不是只支持 NixOS，它明确支持 `nix-darwin`。
- 因此，不能再用“你有 darwin，所以 comin 不适合”这种理由直接否掉它。

但即便如此，`comin` 和 `deploy-rs` 的核心差异仍然成立：

- `deploy-rs`：控制端显式发起部署，谁发、何时发、发到哪几台，都在控制端决定。
- `comin`：目标机自己观察 Git 状态并尝试收敛，部署更接近持续过程，而不是一次显式发布动作。

所以真正的区别不是 “支不支持 darwin”，而是：

- 你要的是 **命令驱动的发布**
- 还是 **Git 驱动的持续收敛**

### 2. 最可能让人反感的，不是功能缺失，而是控制模型变化

如果把主链路切到 `comin`，最容易出现的不适感往往不是 “它做不到”，而是 “它做事的方式变了”。

最明显的几个点：

- 失去显式发布动作：从 `task deploy` 变成 “push 后等节点自己收敛”。
- 失去集中式调试入口：问题会分散到每台目标机本地，而不是控制端一次看完。
- 坏提交更容易自动传播：push 到被监听分支后，节点会在下一轮轮询里尝试评估、构建、部署。
- 桌面机体验可能更差：对 `nix-darwin` 这类工作站来说，“机器自己切换配置”未必比手动触发更舒服。

这也是为什么：

- 服务器场景通常更容易喜欢 `comin`
- 工作站场景未必会喜欢 `comin`

### 3. `comin` 会把复杂度从控制端，转移到每个节点

`deploy-rs` 的复杂度更多在控制端：

- flake outputs
- inventory adapter
- Taskfile 封装
- SSH/target selection

而 `comin` 的复杂度更容易落到节点侧：

- 每台机器都要能访问 Git 仓库
- 私有仓库认证要逐台配置和轮换
- 每台机器都要能独立评估/构建/部署
- 监控、日志、失败排查会变成分布式问题

所以 `comin` 不是“让系统更简单”，而更像是：

> 把部署复杂度从“中央控制”换成“节点自治”。

### 4. `comin` 会明显抬高 binary cache 的重要性

如果主链路切成 pull-first，binary cache 的价值会比现在更高。

原因很简单：

- 没有 cache 时，每台目标机会自己重复构建。
- 机器越多，重复构建越浪费。
- 工作站/小机器做本地构建，体验很容易变差。

因此切到 `comin` 后，`Attic` / `Cachix` 这类 cache center 会更接近推荐标配。

需要强调的是：

- `comin` 解决的是 **谁触发部署**
- `Attic` / `Cachix` 解决的是 **构建产物从哪里复用**

它们互补，但不互相替代。

### 5. 对当前仓库，`comin` 更像一次架构换挡，而不是小增强

当前仓库已经把 `deploy-rs` 做成正式主链路，且理由清楚：

- inventory 已从具体部署工具里解耦
- `deploy-rs` 成为唯一部署入口
- `deployChecks` 已接入 flake checks
- Taskfile 已围绕 `deploy-rs` 封装日常入口

在这个前提下，引入 `comin` 不是“多一个工具试试”，而是：

- 重新定义主机部署由谁驱动
- 重新定义回滚、确认、发布时机
- 重新定义认证、监控和排障位置

所以它的决策级别，更接近 “切换部署范式”，而不是 “加一个 deploy helper”。

## Current Conclusion

当前更稳妥的判断是：

- `comin` 值得研究，也确实对当前仓库有吸引力。
- 但它吸引人的地方主要是 pull-first / Git-driven host reconciliation，而不是单纯因为它支持 `nix-darwin`。
- 如果未来真要切过去，最好连 binary cache 一起纳入设计，否则很容易在重复构建、节点侧负载、排障体验上产生反感。

一句话总结：

> `deploy-rs` 更像“我来发布”；`comin` 更像“机器自己收敛”。
> 前者的复杂度集中在控制端，后者的复杂度分散在每个节点。

## Follow-up

如果后续继续评估 `comin`，最值得先单独判断的几个问题是：

1. 哪些机器适合 pull-first，哪些机器仍应保留 push-first。
2. `nix-darwin` 工作站是否真的适合自动收敛，而不是手动触发。
3. 是否要把 `Attic` / `Cachix` 作为 `comin` 的配套基础设施一起上。
4. 如果采用混合模式，如何避免 `deploy-rs` 和 `comin` 双轨并存导致心智分裂。
