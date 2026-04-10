---
title: 初探Determinate Nix
isOriginal: true
---


:::tip[前言]

这是一篇迟到了的，对于 `Determinate Nix`的 evaluation

因为已经从去年11月份，把workstation从`Linux Desktop`重新换回MBP，也已经过了将近半年了。之所以没有使用Nix官方的 `nix-darwin`安装，因为之前在使用官方方案时，有过 GC + prune generations 时，直接把 nix-darwin 本身直接删掉了（也就是把nix本身搞挂了），当时具体是什么情况，现在已经记不清了，但是真的是非常惨痛的记忆，所以这次转向到了 `Determinate Nix`。

但是之所以仍然认为是 evaluation，而非 review，是因为确实还是没太把这玩意玩明白，并且至今也不确定是否什么时候就用回 `nix-darwin` 官方方案了。

:::

## 问题起点：从发现 `rebuild` 没有命中 cache 开始

:::tip

相关解决方案查看

[feat(flake): 给Determinate Nix配置cache · xbpk3t/dotfiles@e602834](https://github.com/xbpk3t/dotfiles/commit/e6028341af799a105159c2e8339ee6f9411874f8)

[fix(nix): 处理部分 deploy时的 evaluation warning 报错 · xbpk3t/dotfiles@29e2e9a](https://github.com/xbpk3t/dotfiles/commit/29e2e9aa337a42b678c4ac734321bd4bf1f85296)

:::

这篇文章真正的起点，并不是“我想评测 Determinate Nix”，而是一次很具体的问题排查。

当时我是为了让 Darwin 侧的 `codex` 复用 `llm-agents` 的包源，并顺手把对应的 cache 配上。按直觉来说，这类问题通常不会太复杂：补上 `substituters` 和 `trusted-public-keys`，然后重新 `darwin-rebuild`，理论上就应该优先命中二进制缓存，而不是继续在本地从头 build。

但实际情况并不是这样。

### 第一层现象：明明已经加了 cache，还是在本地 build

最开始看到的症状非常像一个普通的 cache 配置问题：

- `rebuild` 过程中没有稳定命中预期缓存；
- 日志里不断出现 `untrusted` 一类的提示；
- 结果上看，系统依然在本地继续 build，而不是直接拉取现成闭包。

```log
warning: ignoring untrusted substituter 'https://nix-community.cachix.org', you are not a trusted user.
Run `man nix.conf` for more information on the `substituters` configuration option.
```

如果只看表面，这很容易被理解成两个方向之一：

- cache 地址写错了；
- key 不匹配，导致 substituter 不被信任。

这当然不是完全错误，但它还不够接近根因。

### 第二层排查：问题不只是 cache，而是配置到底有没有被 daemon 读到

继续往下看之后，问题开始从“cache 配置本身”转向“配置是通过哪条链路生效的”。

这里也是我后来觉得最值得写下来的地方：在 Darwin + Determinate Nix 这套组合里，你并不能简单沿用在 NixOS 上那种“把配置写进 `nix.settings`，然后假设 daemon 一定会按你想的方式读取”的心智模型。

我当时真正踩中的，不是 cache 地址本身，而是配置生效路径：

- 有些配置写进 flake 的 `nixConfig`，更像补充；
- 有些配置写进 `nix-darwin` 的 `nix.settings`，在官方 Nix 路径下是成立的；
- 但在 `Determinate Nix + nix-darwin` 的组合下，真正决定 daemon 行为的入口并不在这里。

这也解释了为什么会出现一种很反直觉的体验：你明明“已经配置了”，但系统表现得像“根本没配置”。

### 根因：Darwin 上真正接管 Nix runtime 的不是 `nix-darwin`

把问题追到最后，结论其实很简单：在我当前这套 Darwin 环境里，真正接管 Nix runtime 的并不是 `nix-darwin`，而是 Determinate 自己的运行时管理路径。

Determinate 官方文档对这一点说得很明确：如果要和 `nix-darwin` 一起使用，就应该让 Determinate 来负责 Nix 自身的配置，而不是继续让 `nix-darwin` 管理 Nix 本体；在这种模式下，自定义配置的受支持入口是 `nix.custom.conf`，而不是直接期待 `nix-darwin` 接管所有 Nix 运行时细节。

也就是说，这次排查最后把我带到了一个比 cache 更基础的问题上：

> 在 Darwin 上，我到底是在用 `nix-darwin` 管 Nix，还是在用 Determinate 管 Nix？

只要这个边界没想清楚，后面很多现象都会显得很怪：为什么某些配置不生效，为什么 `flake.nix` 里的 `nixConfig` 不够，为什么最后还是得回到 `nix.custom.conf` 或 `determinateNix.customSettings` 这种入口。

从这个角度看，这篇文章的主题其实也就自然成型了：我原本只是在排查一次 cache miss，最后却被迫重新回答一个更大的问题，`Determinate Nix` 到底是在替我解决什么问题。

## Determinate 到底是什么

如果只看名字，很多人第一次接触时很容易把 `Determinate Nix` 理解成“另一个 Nix 安装脚本”或者“给 Nix 换了一层包装”。但如果顺着官方文档和实际使用场景往下看，它明显不只是这个定位。

### 它不是单一工具，而是一套围绕 Nix runtime 的产品组合

`Determinate` 首先是 `Determinate Systems` 这家公司，而不是一个单独的二进制程序。围绕 Nix，他们现在至少做了几件相互关联的事情：

- `nix-installer`：一个跨平台的安装器，负责把 Nix 以更一致的方式落到 macOS、Linux、WSL 等环境里；
- `Determinate Nix`：基于 Nix 的下游发行与运行时增强；
- `FlakeHub`：围绕 flakes 的发布、发现和分发平台；
- 以及进一步偏组织治理、供应链和企业场景的配套能力。

所以如果只把它理解为“替代 `curl | sh` 的安装脚本”，其实会低估它真正想做的事情。

### 它的核心卖点不是配置表达，而是 runtime 托管

我现在越来越倾向于用一句话概括它的核心价值：

> Determinate 的优势主要不是“把配置写得更优雅”，而是“把 Nix runtime 托管得更完整”。

这里的 runtime，指的是这些更靠近系统运行层面的事情：

- Nix 在 Darwin 上怎么安装；
- `/nix` 这套存储是怎么落地和维护的；
- daemon 由谁管理；
- cache 信任、证书、升级、卸载、恢复这些动作由谁来负责；
- 当你不再只把 Nix 当成“一个包管理器”，而是当成一套长期运行的基础设施时，谁来兜住这些边边角角。

这也是为什么我会觉得它和 `nix-darwin` 很容易被混淆。

`nix-darwin` 解决的是“如何在 macOS 上声明式管理系统配置”；而 Determinate 更关心的是“如何把 Nix 这套运行时本身稳稳地装上去、跑起来、管起来”。两者当然会发生交集，但它们不是在同一个层面上提供价值。

### 对我这次排查最关键的启发

一旦接受“Determinate 主要在管 runtime，而不是替代 `nix-darwin` 的声明式能力”，很多之前看起来反直觉的事情就顺了：

- 为什么 Darwin 上的配置入口会和 NixOS 不完全一样；
- 为什么 `nix.settings` 在某些路径下并不是最终生效点；
- 为什么 Determinate 的“好用”更多体现在安装、升级、回收、卸载、系统集成这些地方，而不是模块写法本身。

换句话说，它真正擅长的不是让 Darwin/NixOS 配置完全同构，而是把 Darwin 上的 Nix runtime 变成一套更可控的系统部件。

## Darwin 上安装 Nix，到底在选什么

如果把问题只写成“Darwin 上该用哪个安装方案”，其实会有点失焦。因为这里真正的差异，并不只是安装命令长什么样，而是谁来接管 Nix runtime，以及你愿不愿意接受由此带来的心智差异。

### 官方方案：官方安装脚本 + `nix-darwin`

截至目前，Nix 官方在 macOS 上推荐的入口依然是 `nixos.org/nix/install` 这条安装脚本。官方下载安装页给 macOS 的命令仍然是通过这条脚本完成多用户安装，而不是别的发行版或分支。

这条路线的优点很明确：

- 更贴近 upstream；
- 心智模型更统一；
- 如果你本来就想让 `nix-darwin` 尽量直接管理 Nix 本体，那么这条路线通常最自然。

但它的代价也很真实，尤其在 Darwin 上：你需要自己更清楚地知道 Nix runtime 是怎么工作的，出了问题时排查、回收、恢复、卸载这些动作，也更依赖你自己的理解和经验。

我这次没有直接回到官方方案，很大一部分原因，其实就是被之前那次 GC / prune generations 的事故留下了心理阴影。虽然我现在已经记不清当时的完整细节，但可以 reasonably 推测，问题大概率不是“官方 Nix 会无缘无故把自己删掉”，而是当时 Darwin 侧某些关键闭包没有以我以为的方式被稳定引用住，结果在清理 generations 和 GC 之后，把整套Nix一起带崩了。

这也是为什么我后来会明显更关注“谁来托管 runtime”这个问题，而不只是“配置写法够不够优雅”。

### Determinate 方案：让 `nix-darwin` 管系统，让 Determinate 管 Nix 本体

Determinate 和 `nix-darwin` 的组合，本质上是一种明确分工：

- `nix-darwin` 继续负责 Darwin 侧的声明式系统配置；
- Determinate 负责 Nix 自身的安装、daemon、配置入口、以及部分运行时行为。

这个方案的直接好处，是 Darwin 上很多 historically 比较容易让人心里没底的 runtime 问题，会被它打包成一套更“工程化”的路径。例如安装器、卸载、`/nix` 的落地方式、daemon 行为、配置入口等，都有更强的统一性。

但代价同样很清楚：

- 你要接受它不是纯 upstream 的 Nix；
- 你要接受 Darwin 侧的配置入口会与 NixOS 存在分叉；
- 你还要接受社区对它一直存在一些两极化评价，尤其涉及下游分叉、FlakeHub 绑定、以及和上游治理关系的问题。

所以它不是“全面更好”，而是“把优先级换了一下”。

### Lix 在这里是什么位置

`Lix` 也值得单独提一下，因为它很容易在搜索时和“官方 Darwin 安装方案”混在一起。

但至少到现在，`Lix` 并不是 Nix 官方在 macOS 上的新默认安装路径。它更像是另一个独立项目：有自己的发行方向、自己的安装器、自己的兼容承诺。你可以把它看成“Nix 生态里另一条明确存在的分支路线”，但不应该把它误认为“官方已经迁过去了”。

所以如果把 Darwin 上的现实选择简单粗暴地概括一下，大致是：

- 想尽量贴 upstream 心智，走官方安装脚本；
- 想把 Darwin 上的 Nix runtime 托管得更完整，走 Determinate；
- 想进一步尝试另一条分支路线，可以关注 Lix，但它不是这篇文章要重点展开的主角。

### 综合比较

如果一定要把这三条路线放在一起看，我更愿意按下面几个维度来比较：

- 是否贴近 upstream；
- 是否能和 `nix-darwin` 自然配合；
- 是否明显偏向 runtime 托管；
- 是否更容易维持统一的配置心智；
- 安装/卸载链路是否足够工程化；
- 是否需要接受额外的下游分叉或生态绑定。

之所以选这几项，是因为它们比“好不好用”更接近真正的技术分歧。Darwin 上几种方案的差异，核心并不在于能不能安装成功，而在于你到底更看重 upstream 一致性、声明式配置统一性，还是 runtime 的托管能力。

```yaml
- name: "官方 Nix + nix-darwin"
  贴近_upstream: "✅"
  可与_nix_darwin_直接配合: "✅"
  偏向_runtime_托管: "❌"
  配置心智更统一: "✅"
  安装卸载更工程化: "❌"
  需要接受下游分叉或生态绑定: "❌"
  判断说明: "最接近上游，也最符合把 Nix 本体继续交给 nix-darwin 管理的直觉；代价是 runtime 层面的安装、恢复、卸载、排障更依赖使用者自己理解。"

- name: "Determinate Nix + nix-darwin"
  贴近_upstream: "❌"
  可与_nix_darwin_直接配合: "✅"
  偏向_runtime_托管: "✅"
  配置心智更统一: "❌"
  安装卸载更工程化: "✅"
  需要接受下游分叉或生态绑定: "✅"
  判断说明: "核心优势在于把 Nix runtime 的安装、daemon、配置入口、卸载等问题托管起来；代价则是需要接受 Darwin 侧与 upstream 不完全一致的配置路径，以及额外的产品边界。"

- name: "Lix + nix-darwin"
  贴近_upstream: "❌"
  可与_nix_darwin_直接配合: "✅"
  偏向_runtime_托管: "❌"
  配置心智更统一: "❌"
  安装卸载更工程化: "✅"
  需要接受下游分叉或生态绑定: "✅"
  判断说明: "它不是 Nix 官方路径，也不是 Determinate 那种以 runtime 托管为核心卖点的产品组合，而是另一条独立实现路线；可以与 nix-darwin 协作，但同样意味着要接受分支实现本身带来的额外判断成本。"
```






## 我的决策

写到这里，我自己的结论其实已经比较明确了。

我现在并不觉得 Determinate 是一个“放之四海而皆准”的更优方案。相反，我觉得它最大的特点恰恰是价值边界非常清楚：它更强的是 runtime 托管，而不是配置统一性。

这意味着，如果你的首要目标是：

- Darwin 和 NixOS 尽量共用一套配置心智；
- 尽量减少平台分叉；
- 尽量贴近 upstream；

那么官方方案通常更顺。

但如果你的首要目标变成：

- 我主要在 macOS 上长期使用 Nix；
- 我更在意安装、升级、daemon、卸载、恢复这些 runtime 层面的稳定感；
- 我愿意接受一定程度的下游分叉，换取更完整的托管体验；

那 Determinate 确实会变得更有吸引力。

对我自己来说，这次的实际选择依然是继续站在 Determinate 这边，至少在当前阶段如此。原因并不复杂：我现在对 Darwin 上 Nix runtime 的“可恢复性”和“可托管性”比对“配置完全同构”更敏感。前一次事故留下的阴影还在，而这次 cache miss 排查又恰好提醒了我，Determinate 真正解决的，正是这类更靠近运行时边界的问题。

但这篇文章之所以仍然只能叫 evaluation，而不是 review，也正是因为我并没有因此得出一个彻底封闭的结论。

一方面，我承认自己已经明显感受到 Determinate 的取向和价值；另一方面，我也同样感受到它带来的配置分叉、心智差异，以及和 upstream 并不完全一致的那部分代价。是否会在未来某个时间点重新回到官方 Nix + `nix-darwin`，我现在并不敢说不会。

如果一定要把这篇文章压成最后一句话，那大概就是：

> 我最开始以为自己只是在排查一次 Darwin 上的 cache miss，最后却发现，我真正需要重新判断的，是在 macOS 上到底该把 Nix 当成一个自己完全掌控的工具，还是一套更值得被托管的 runtime。
