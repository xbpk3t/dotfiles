---
title: 初探 comin
type: evaluation
status: active
date: 2026-03-25
updated: 2026-03-25
isOriginal: false
tags:
  - nix
  - comin
  - deploy-rs
  - deploy
  - gitops
summary: 评估 comin 作为 pull-first 主机部署方案时，对当前仓库的吸引力、风险和不适配点。
---



:::tip[TLDR]

本文为GPT生成，这里写点自己的想法，以及本文的总结：

目前deploy存在两难，我讨厌 deploy-rs/colmena 这套 push-mode，总要等待，并且难以保证所有配置项可以实时同步。

具体来说，这里存在两难：

- 1、多端部署问题。也就是必须要手动执行命令来部署指定host
- 2、push-mode 需要保证控制端不掉（尤其在控制端通常是workstation的情况下，不知道多少个凌晨，在改完配置后，都要等着deploy完成，验证确实可用之后，才放心commit代码，非常操心伤神），否则部署流程被打断，就会失败。


当然，这两个方案都有办法克服掉

- 1、针对问题1，我现在 `.taskfile/nix/Taskfile.deploy.yml` 里面直接用 gum choose 来多选hosts，来批量部署。但是这里到具体细节，同样存在两难，也就是“并行部署和multi-platform问题”，colmena支持并行部署，但不支持多平台，deploy-rs支持多平台，但不支持并行部署。
- 2、针对问题2，可以用 zellij 登录 homelab，然后用homelab来作为控制端，来对所有hosts做deploy 来解决。能明显缓解“workstation 掉线导致部署中断”的问题。但它没有从范式上规避 push-mode，只是把控制端从“不稳定的人机终端”换成“更稳定的常驻机器”。

---


> ***如果按照上面的说法，是否就是说 pull-mode 就真的远胜于 push-mode方案了？***

也并非如此，用了 pull-mode 之后，上面两个问题可以迎刃而解，但是也会带来一些新问题。

一些显而易见的新问题：

pull-mode 相比 push-mode 的要求更高，具体来说：

- 1、运维要求
- 2、对 main branch 代码质量要求

前者的意思是，`pull-mode` 并不是让复杂度消失了，而是把复杂度从控制端转移到了节点侧。发布时机、回滚语义、日志排查、Git 访问、凭据管理、状态观测，这些事情都会变得更分布式，也更依赖配套基础设施，而不再像 `push-mode` 那样主要集中在控制端解决。

后者的意思是，`pull-mode` 会减少“人工触发 deploy”这一层天然闸门，只要目标分支成为事实源，节点就会陆续向它收敛。这样一来，坏提交的传播半径会更大，对 branch protection、CI gate、deploychecks、staging 验证的依赖也会更强。也就是说，`pull-mode` 不是没有代价，而是用更高的运维要求和更高的分支质量要求，换来了更弱的控制端依赖和更接近 GitOps 的部署模型。

:::





```markdown
## nlewo/comin (3/5)

URL: <https://github.com/nlewo/comin>

具体原因：

- 你的仓库已经在 Kubernetes 层采用了明显的 GitOps 思路：[`homelab-flux-sync.sh`](homelab-flux-sync.sh) 和 `manifests/` + Flux 已经证明你接受“Git 为事实源”。
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

- Kubernetes workload 层已经是明显的 GitOps/pull 模式，见 [`homelab-flux-sync.sh`](homelab-flux-sync.sh) 与 `manifests/`。
- 主机层已经收敛到 `deploy-rs`，而且是有意为之，不是临时拼出来的，见 [`docs/deploy/deploy-rs-migration.md`](docs/deploy/deploy-rs-migration.md)。
- `deploy-rs` 已经深度接入 flake outputs、checks、inventory adapter 和 Taskfile，见 [`outputs/default.nix`](outputs/default.nix)、[`lib/inventory/utils.nix`](lib/inventory/utils.nix)、[`/.taskfile/nix/Taskfile.deploy.yml`](.taskfile/nix/Taskfile.deploy.yml)。

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


## ***push-mode vs pull-mode***

如果进一步展开，`pull-mode` 相比 `push-mode` 带来的新增成本，基本都可以归到上面那两类：

- 运维要求更高
- 对 `main` branch 代码质量要求更高

下面这些差异，并不是另起一套分析框架，而是在解释这两点为什么会成立。前者主要体现在发布控制、回滚、排障、凭据管理、状态观测等方面；后者则主要体现在坏提交更容易自动扩散，因此会更依赖 branch protection、CI gate、deploy checks 和 staging 验证。

### 1. 发布控制权从“中心显式控制”转向“节点自治收敛”

这是最核心的一条，很多后续问题都从这里长出来。

一句话说，就是：

> `push-mode` 强在“我明确地下达一次发布动作”；`pull-mode` 强在“机器自己持续逼近目标状态”。

#### 1.1 发布时机变得不再那么“可控”

`push-mode` 是你手动下达一次部署动作，什么时候发、发到哪台、先后顺序如何，都很明确。

而 `pull-mode` 下常见问题是：

- 节点何时收敛，取决于轮询周期、timer、hook 或 watcher，不再是“我现在按下去就开始”。
- 多台机器不一定同时更新，容易出现一段时间内的版本漂移。
- 如果你想分批发布、灰度发布、按顺序发布，就要额外设计机制，而不是天然拥有。
- “代码已经 merge” 和 “所有节点都完成切换” 不再是同一个时刻。

#### 1.2 回滚语义会变复杂

`push-mode` 的回滚通常比较直觉：

- 你选择上一版。
- 你对指定目标重新 deploy。
- 回滚动作本身是显式的。

而 `pull-mode` 下常见麻烦是：

- 如果 Git 已经推进到坏提交之后，节点会继续朝“仓库当前状态”收敛。
- 想回滚，往往要 revert commit，或者人为改回目标 revision。
- 回滚动作和正常发布动作在形式上可能没那么容易区分。
- 不同节点可能已经分别处于不同代际，导致回滚窗口不一致。

所以它不是不能回滚，而是回滚心智模型往往更绕。

### 2. 风险传播模型变了：人为闸门减少，坏状态更容易自动扩散

这是第二个本质问题。

也就是说：

> `push-mode` 的默认风险模型更偏“先人工触发，再传播”；`pull-mode` 更偏“只要 Git 成为真相源，节点就会自动跟进”。

#### 2.1 坏提交的传播半径更大

这是 `pull-mode` 最现实的问题之一。

- 一旦监听的 branch 上出现有问题的提交，所有订阅它的节点都可能陆续尝试应用。
- `push-mode` 下你至少还要主动执行 deploy，天然多了一层人为闸门。
- 如果缺少分支保护、CI gate、deploy check、staging 验证，`pull-mode` 很容易把错误自动扩散。
- 出问题时，影响常常不是“一台没 deploy 成功”，而是“多台机器都在尝试收敛到错误状态”。

所以 `pull-mode` 往往会显著提高对 `main` 分支质量的要求。

### 3. 运维复杂度从控制端集中式，迁移到节点侧分布式

这是第三个本质问题，也是最容易低估的一条。

本质上就是：

> `pull-mode` 不是让复杂度消失，而是把复杂度从“中央调度”搬到“节点自治”。

#### 3.1 排障会从“中心化”变成“分布式”

`push-mode` 出问题时，很多时候你在控制端看一次输出就知道大概卡在哪。

`pull-mode` 则会把问题分散到每台机器本地：

- 每台机器都可能有自己的拉取失败、评估失败、构建失败、切换失败。
- 你需要逐台看 journal、service log、timer log，而不是只看一次 deploy 输出。
- 同一个提交，可能在 A 机器成功、B 机器失败、C 机器延迟很久才执行。
- 故障定位路径更长，观测和日志聚合要求更高。

也就是说，`pull-mode` 不会减少复杂度，只是把复杂度从控制端搬到节点侧。

#### 3.2 对 Git 仓库访问和凭据管理要求更高

`push-mode` 里通常只有控制端需要完整访问仓库和部署权限。
`pull-mode` 则是每个节点都要自己拿代码：

- 每台机器都要有 Git 仓库读取能力。
- 私有仓库时，需要逐台配置 deploy key、token、SSH key 或其他认证方式。
- 凭据轮换、过期、权限收敛会变成批量运维问题。
- 如果某些机器网络环境特殊，能 SSH 进它，不代表它能稳定访问 Git provider。
- 节点侧的凭据越多，攻击面也越大。

这在 homelab 还算能接受，机器数量一多就会明显变麻烦。

#### 3.3 观测和通知需求会上升

因为部署动作不再由你手动发起，所以“机器现在到底部署到哪了”会更重要：

- 需要知道每台机器当前跟到哪个 revision。
- 需要知道失败了没有、失败在哪一步。
- 需要知道是否长期落后于目标状态。
- 需要告警和可视化，否则会变成“它应该已经好了吧”的盲区。

换句话说，`push-mode` 更依赖操作时的即时观察，`pull-mode` 更依赖持续性的可观测性建设。

#### 3.4 会引入“双轨心智”风险

如果你不是完全切换，而是部分机器 pull、部分机器 push，就会出现：

- 同一个仓库里存在两套部署入口。
- 出问题时先想“这台到底是谁在驱动部署”。
- 文档、值班、排障、日常操作容易混乱。
- 长期看很容易形成“谁都没彻底维护好”的中间态。

所以混合模式不是不能做，但如果没有明确边界，维护成本会很高。

### 4. 基础设施前提更强，不是“单独换个 deploy 工具”就够了

这是最后一个本质问题。

也就是说：

> `pull-mode` 往往不是一个独立工具选择，而是一整套前提条件成立后才顺手的部署范式。

#### 4.1 对 binary cache 的依赖会变强

这是很关键的一点。

- `push-mode` 下你更容易在控制端统一 build，再把结果 deploy 出去。
- `pull-mode` 下如果没有 cache，每台机器都可能重复评估、重复构建。
- 节点越多，重复劳动越严重。
- 小机器、ARM 机器、桌面机自己本地构建时，体验很容易变差。
- 一旦 cache 不稳定，`pull-mode` 的整体体验也会明显恶化。

所以很多 `pull-mode` 方案其实默认隐含了一个前提：

> binary cache 不是可选优化，而是接近基础设施。

#### 4.2 不适合所有机器类型

`pull-mode` 对服务器通常更自然，但对工作站、开发机、笔电不一定友好：

- 机器可能并不总在线，收敛时机不可预测。
- 你不一定希望桌面机在你工作中自动切换系统配置。
- 某些 darwin/desktop 场景更需要“我准备好了再切换”，而不是后台自动收敛。
- 个人开发机经常带有临时性状态，自动应用声明式配置的收益未必大于打扰。

所以 pull-first 往往更适合“应当持续保持目标状态”的机器，而不是“由人主导交互”的机器。

#### 4.3 对状态建模要求更高

如果走 `pull-mode`，你需要更认真地区分：

- 什么配置适合自动收敛
- 什么改动必须人工确认
- 哪些机器追 `main`
- 哪些机器应该追稳定分支或固定 revision
- 哪些变更需要 staged rollout

`push-mode` 下很多东西可以靠“操作时判断”解决；
`pull-mode` 下则更需要提前把这些策略制度化、代码化。





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
