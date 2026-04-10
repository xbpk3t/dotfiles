---
title: 初探 attic
date: 2026-03-25
type: evaluation
isOriginal: false
---


## zhaofengli/attic (4/5)

URL: [https://github.com/zhaofengli/attic](https://github.com/zhaofengli/attic)

具体原因：

- 你当前已经是多主机、多平台、多 profile 部署仓库，且在 [`outputs/x86_64-linux/src/nixos-homelab.nix`](outputs/x86_64-linux/src/nixos-homelab.nix) 已经显式有 `remoteBuild = true` 这种跨机构建/部署考虑。
- [`lib/nix-cache-settings.nix`](lib/nix-cache-settings.nix) 说明你已经非常依赖 binary cache，只是目前是“消费公共 cache”，不是“自建 cache”。
- 如果你后续想让 `macos-ws` 构建的结果更稳定地复用到 homelab/VPS，或者减少重复构建，Attic 的价值会非常直接。
- 我给 `4/5` 而不是 `5/5`，因为它是**性能/交付效率增强项**，不是当前仓库不可或缺的缺口；你现在并没有因为“没有自建 cache”而卡住主链路。

### Attic 在当前仓库里的定位

Attic 不是用来替代 `deploy-rs` 的，也不是用来替代你当前的 host/module 分层；它补的是 **binary cache** 这一层。
对当前仓库来说，它的价值主要在于把 `builder`、`cache source`、`deployment entry` 三件事拆开：谁负责构建、谁负责分发产物、谁负责发起部署，不必再绑定在同一台机器上。

### 当前 deploy 方案为什么会显得别扭

你现在的主链路本质上是：

- `macos-ws` 作为 deploy entry
- Linux 目标机或 `nixos-homelab` 承担构建
- cache 侧主要还是消费公共 `substituters`

这套方案能跑，但职责缠在一起了：deploy 从 `mac` 发起，Linux system closure 却不能稳定在 `mac` 本地构建，于是你只能把构建责任继续压到远端机器上。
问题不在于这条链路错误，而在于 `deploy`、`build`、`cache` 还没有彻底分层。

### push 和 pull 的区别，以及为什么两者会协同

`push` 和 `pull` 解决的是同一个目标：把正确的 closure 送到目标机并完成激活；但它们解决的是不同阶段的问题。

- `push-first`：更像“这一次部署怎么把 closure 送过去”
- `pull/cache-first`：更像“已经构建过的 closure 怎么被多台机器稳定复用”

因此两者不是互斥关系。
`deploy-rs` / `colmena` 这类工具偏向 deployment transport；`Attic` / `Cachix` 这类工具偏向 binary distribution。
一致性也不来自 `push` 或 `pull` 本身，而来自**最终激活的是同一个 closure hash**。

### 为什么当前更偏向 push-first，但规模变大后 pull/cache-first 更划算

就当前仓库的规模和操作习惯而言，`push-first` 的体验确实更直观：

- 单次部署时更像“我把本地准备好的东西直接送到目标机”
- 目标机不一定要再额外 download
- 对少量 VPS 或临时变更来说，控制感更强

但当机器数量、部署频率、重复构建次数上来之后，`pull/cache-first` 的优势会变得更明显：

- 同一份 closure 不需要从 deploy 入口反复搬运很多次
- 先 build 一次、push 一次，后续多个目标机都可以直接复用
- 失败重试的成本更低，deploy entry 的网络和带宽压力也更小

所以它不是“pull 比 push 更正确”，而是“规模化分发时，统一 cache 更经济”。

### Attic 和 Cachix 怎么选

如果只看抽象层次，可以这样理解：

- `Cachix` 更像第三方 hosted service，开箱即用，运维负担小
- `Attic` 更像 self-hosted binary cache service，需要自己维护

在存储模型上：

- `Attic` 常见做法是接 `S3-compatible storage` 作为后端
- `Cachix` 对使用者暴露的是托管 cache 服务，而不是底层对象存储控制面

对当前仓库来说，如果目标是**尽快得到统一 cache 能力**，`Cachix` 落地更快；如果目标是把 cache 纳入你自己的基础设施体系，和 homelab/VPS 一起长期治理，`Attic` 更贴合。
另外，`Cachix` 有免费层，但不是无限免费；而 `Attic` 的成本主要会转化为你自己维护服务与对象存储的成本。
