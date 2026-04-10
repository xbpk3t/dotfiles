---
title: 初探Android声明式安装APP
type: review
date: 2026-04-10
isOriginal: true
tags:
  - Android
  - NixOS
  - ADB
  - AVF
summary: "在把 NixOS 配置慢慢整理顺之后，我自然也想把 Android 一并纳入类似的管理方式。继续往下研究后，我发现这里其实混着两个问题：Android host 本体的 App 安装与恢复，和 Android 设备作为开发机。前者最终只能落到一份 App manifest 加一套 ADB bootstrap；后者如果真想接近 Nix-like 环境，答案则不在 Android host，而在 AVF 里的 guest。"
---



## TLDR

:::tip[TLDR]

最开始我想解决的其实只有一句话：

**能不能把 Android 也像 NixOS 一样，当成一个 host 来管理？**

最后我发现，这里面其实混了两个完全不同的问题：

- Android host 本体上的 App 安装与恢复，能不能配置化、可重复
- Android 设备能不能成为一台像样的开发机

它们同源，但不能混着答。

我的最终结论是：

- **对于 Android host 本体**，不要幻想什么 `nix-darwin for Android`
- **对于 App 安装与恢复**，现实可行的上限是 `manifest + ADB bootstrap`
- **对于开发环境**，最优解（及最终解）就是 `AVF`，之前的 `Termux`, `nix-on-droid`、root 本身，大概率都只能算是某种“过渡方案”了。
- **真正适合被 Nix 化的**，不是 Android host，而是 Android 上那台 Linux / NixOS guest

:::




## 起点：想把 Android 也纳入“配置即结果”的范围

在把 NixOS 这边的配置慢慢整理顺之后，我很自然地产生了一个想法：

既然桌面和服务器都可以逐渐靠近“配置即结果”，那 Android 手机能不能也做类似的事情？

这个念头本身并不激进。

无非是想把手机上那些重复劳动尽量收拢起来：

- 装哪些 App
- 换机之后怎么恢复
- 重置系统之后如何尽快回到可用状态
- 能不能少一点靠记忆，多一点靠记录和脚本

如果再往前想一步，脑子里就会出现一个更有诱惑力的目标：

**能不能像 NixOS 一样，把 Android 也变成某种可配置、可重复、最好还带点声明式味道的东西。**

甚至会继续延伸出另一个看起来也很顺的想法：

既然手机也是一台 ARM 设备，那它能不能顺便作为随身携带的轻量开发机，甚至直接跑一些服务？

问题也正是从这里开始变复杂的。

因为我后来发现，这里其实不是一个问题，而是两个问题。

## 真正的误区，不是没找到工具，而是一开始把两个问题混在了一起

:::danger

当然，或许说，这也并非是两个问题，只是在 `Android`目前这种厂商主导、深度定制系统的情况下，同一个问题被分化为了两个，因为

:::



我最开始脑子里的目标其实很朴素：

- 让 Android 也像一个 host
- 能用类似 Nix / Home Manager 的方式管理环境和应用

但继续往下看之后，会发现这个目标其实裂成了两部分：

### 1. Android host 本体的 App 安装与恢复，能不能配置化

这里关心的是：

- 装哪些 App
- 包名是什么
- 来源是什么
- 换机或重置之后怎么补回来
- 能不能把手工点点点收敛成一个可以重复执行的流程

这本质上是在问：

**Android host 本体，能不能被“半声明式”地管理。**

### 2. Android 设备能不能作为开发机

这里关心的则是另一套东西：

- 有没有像样的 shell 和工具链
- 能不能运行完整的 Linux 用户态
- 能不能跑容器、服务、守护进程
- 能不能像一台真正的 Linux host 一样长期维护

这本质上是在问：

**Android 设备上，能不能获得一个更像 NixOS / Linux host 的运行环境。**

这两个问题当然相关。

但它们不是同一道题。

一旦混着答，整个讨论就会一直飘在半空里：看起来涉及了 AVF、root、Termux、`nix-on-droid`、F-Droid、ADB、Shizuku 这些名词，但每条线都只沾了一点边，最后反而很难落出一个稳定结论。

所以更准确的做法，是先把这两个问题拆开。





## 1、声明式安装APP


:::tip

***目前没有 declarative 管理APP的方案。至于整个手机配置，就更不现实了。没必要幻想什么“手机配置完全nix化”***，更现实的目标是：

- 1、有APP清单
- 2、通过 `adb` 来清除预装APP

---

具体查看代码


- [android.nix](home/base/tui/zzz/android.nix) 里面安装 `fdroidcl`
- [Taskfile.droid.yml](.taskfile/devops/Taskfile.droid.yml) 核心代码


:::


下面来说说是怎么收束到当前这个方案的：

首先，手机系统不同于电脑，并非可以直接分为 Windows, Mac, Linux 这么三类，而是由各手机厂商深度定制的（这里排除掉ios，只讨论Android），而各家都不一致，压根没有像 nix生态给这几家做适配，很显然这些主流手机厂商也没有任何动机去主动做nix适配。所以这里没有“怎么用nix去配置手机”的讨论空间。比如说：


- 登录态怎么恢复
- 应用内部配置怎么恢复
- 权限怎么恢复
- 后台、自启动、电量优化怎么处理
- 应用本身有没有导入导出能力

当然，我看到nix社区跟我同样想法的人也有很多，并且已经有一些实质进展了，比如说


[Nix Android? : r/NixOS](https://www.reddit.com/r/NixOS/comments/1l2dxyt/nix_android/)

[Nixos for android : r/NixOS](https://www.reddit.com/r/NixOS/comments/1caohq7/nixos_for_android/)

[mobile-nixos/mobile-nixos](https://github.com/mobile-nixos/mobile-nixos)

[nix-community/robotnix](https://github.com/nix-community/robotnix)


[Building Custom Android Kernel with Nix - Lan Tian @ Blog](https://lantian.pub/en/article/modify-computer/build-custom-android-kernel-with-nix.lantian/)






```yaml
        移除【Droid-ify】、【Shizuku】这两个repo。“最像包管理器的是 Privileged Extension（通常需 system app/ROM 集成或 root）；不 root 可走 Shizuku + Neo Store/Droid-ify”、“用无线调试启动 Shizuku，授权 Droid-ify；Droid-ify 支持 Shizuku 安装方式。Neo Store 可导出/导入 app 清单以便恢复（但多仓库可能有歧义）。” 这套东西意思不大，少折腾就手动/系统迁移；换机频繁就做清单化；只有追求可复现/愿意维护自动化链路才值得上 Nix 管清单或 Shizuku。想要像 nix-darwin 那样对整个手机系统做预设，是不可能的，最多也就只能做到以上这种自动安装APP（但是也仅限于 F-Droid 支持的这些开源APP）

        ***关于Android这个东西，归根到底问题在于我的需求不清晰，到底是要预配置，还是作为开发机使用***

        这其实是两码事

        1、本身无法实现预配置。预装APP是宿主机这层处理的，现在的主流方案是 Droid-ify + Shizuku，跟nix不搭噶，也没办法用nix做预制（毕竟不存在nix-darwin这样的东西，安卓手机生态过于分散，且也没有一个类似）
```


有哪些约束条件？-> 这里来澄清部分认知

其实核心在于这里的几个边界：


真正需要声明式管理的，是 Android 上那台 NixOS guest；而不是强行把 Android 本体改造成第三个 Nix host。


[ImranR98/Obtainium: Get Android app updates straight from the source.](https://github.com/ImranR98/Obtainium?tab=readme-ov-file)











## 2、把 Android 当开发机（AVF）

如果我们把需求放到“把手机当开发机”用，那么可选方案就很多了。我们这里逐个做个排除，并说明为什么 `AVF` 就是最优解和最终解。


:::tip[TLDR]

作为开发机，就是3条路线：

- Termux本质是个APP，相当于某个用户态里面做了linux这套（但是只有一层皮）
- Termux+QEMU. 我看到有人在Termux里跑container（甚至k3s），这个实际上是通过Termux+QEMU实现的。不是 Android 宿主直接跑容器。QEMU 路线“能成”，但性能/续航/复杂度成本高。完全没意义。
- AVF本质是个VM（可能通过 Terminal/Linux VM 的入口呈现），本身提供了全套linux能力（甚至可以用nixos-avf刷成nixos，玩法就彻底打开了）

***最终总结：对我的需求来说，Termux太鸡肋了，而 Termux + QEMU 又会影响手机日常使用。所以最优解就是换个支持AVF的手机。***

这里还有个附加问题：有了AVF之后，还有必要root吗？没必要


:::



### Termux

:::tip

***首先来看 `Termux` 这个***


:::


它本质上还是 Android 上的一层 app 用户态环境。

也就是说，它更像：

**“一台 Android 手机上很好用的 Linux 终端”**

而不是：

**“一台完整的、适合长期当 host 维护的 Linux 机器”**

如果只是想临时做点 CLI 工作，它当然成立。
但如果目标已经变成“随身开发机”甚至“能跑更完整服务的 host”，它就会开始显得有点鸡肋。


### nix-on-droid

:::tip

***再来看 `nix-on-droid`，本质上其实***

:::



```yaml
    - date: 2025-12-24
      des: |
        移除【nix-community/nix-on-droid（Android 上的 Nix 环境。本质上是 termius）】。这玩意就是个client，而对我来说，笔记本永远在手边、而且就是最佳 client，并且希望所有其他设备都应该是server。所以对我来说，我是希望可以直接 ssh 到这台手机上的，但是如果不能作为server，就没啥意思了。
        用NOD有啥好处（或者说，大部分人用NOD的目的是啥）？

        其实这么看下来，我感觉NOD没啥意思，不如等有了AVF之后，可玩性大大提升之后再玩？

        1、作为 开发机，跑不了container，鸡肋（NOD 的核心基建就是 PRoot/proot-static 这类用户态 chroot/bind-mount 模拟，它本来就不是为容器/系统服务那套内核能力准备的）
        2、作为 运维机（也就是client，笔记本不离身的话，意义同样不大）
        3、常驻服务。我看了一下有点麻烦，AVF本身就是以此为卖点的。

    # 1、nix-on-droid 的核心价值是把 Nix 变成一个很强的“本机终端环境/工具箱”（客户端形态）。你不需要这个，因为你已经有“随身最佳 client（笔记本）”。
    # 2、你真正想要的是“手机作为 server”：可被 ssh、能长期跑服务、可维护、可预期。这恰好是 Android（尤其未 root）最不擅长的形态：后台保活、省电策略、网络切换、端口暴露等会让它作为 server 的体验非常不稳定；而 nix-on-droid 并不会从根上解决这些系统级问题（它主要跑在 app 沙盒/用户态）。
    # 3、即便你 root 后去折腾“真 server”（比如让手机跑 Linux chroot/甚至 docker），那也基本是另一条路，和 nix-on-droid 关系不大；nix-on-droid 最多作为“在手机上装 CLI 的一种方式”，但你既然本来就不把手机当 client，这个加成也不大。

```






### Termux + QEMU

:::tip
***这里还有个邪修办法， `Termux + QEMU`***（比如 [devopsexpertlearning/termux-kubernetes-docker](https://github.com/devopsexpertlearning/termux-kubernetes-docker)）

:::



### 为啥现在不推荐root?

:::tip

***那root呢？直接把手机刷成Linux，那肯定就能突破上面这些问题了，不是吗？***

:::


手机刷linux，为啥不推荐直接刷宿主机？

```yaml
# 手机刷linux

#  手机刷linux可能是某种美好期待，手机刷linux大概3种方案。
#  1、虚拟容器（Termux+PRoot，在安卓内模拟Linux用户空间）
#  2、Root虚拟化（Linux Deploy，通过Root权限创建Linux容器）
#  3、完整刷机（Ubuntu Touch，替换安卓为定制Linux系统）。从。
#  总之如果要用手机刷linux作为VPS，就一定要面临 功能完整性（驱动、硬件支持）-系统稳定性（性能、功耗、安全）-使用便捷性（安装、维护成本）这个不可能三角制约，是一定要做tradeoff的。

# 想稳定用手机 → 优先考虑 LineageOS 一类 Android ROM，或干脆保持原厂系统。
# 想玩真·Linux → 用备用机刷 postmarketOS/Ubuntu Touch，或者先从 Termux 容器玩起。

# 刷LineageOS 之后，仍然是Android手机。刷postmarketOS之后，就变成linux机器了。如果并不需要手机在刷机之后仍然可以接打电话，应该采用哪个方案？能否把手机刷成开发机？比如说作为 Dokploy remote server 使用？
# 如果你不在乎能不能打电话，只想把手机当“小 Linux 服务器 / 开发机”用：
#→ 首选路线：postmarketOS（或类似真·Linux），把手机当一台 ARM 小服务器来用。
# 如果你并不一定要“刷机”，只是想有个远程开发环境：
#→ 更务实的路线：保留 Android + 装 Termux，当 Linux 开发机用。
```





```yaml
## 一加（国行 ColorOS 16 起）：改成“申请加入深度测试 → 审核通过 → 获得解锁 BL 权限”，官方明确说不需要答题、目前没有名额限制、一般 1–2 个工作日审核。
## 小米（尤其国行 HyperOS 这两年）：仍然有官方解锁渠道，但规则更“考试/资格审查/限制”——例如新增资格审查（账号注册天数、社区违规记录、设备/IP 变动等），以及一些时间窗口/台数限制等。
#
# 最核心的因素是安全。锁定Bootloader是防止恶意软件获取系统最高权限、保护用户敏感数据和支付安全的关键防线。
# 随着小米用户群体的急剧扩大，其中包含了大量非技术背景的普通消费者。对这部分用户而言，官方统一管控的系统环境能显著降低因误操作或刷入不兼容/恶意ROM导致设备变砖、数据丢失或遭受安全攻击的风险。
#
#
```

你觉得在2026年的今天，把手机root掉的得失有哪些？还有什么比较大的损失或者收益吗？基于什么特殊需求，需要root掉？又或者基于什么约束，不应该root掉呢？

```markdown
我现在的判断是：**2026 年还去 root，可以，但已经从“进阶玩家常规操作”变成了“有明确系统级需求才值得做”的事。** 技术上它没死，Magisk 官方仓库还在持续更新，最近版本甚至明确写了支持 Android 16 QPR2 和 Zygisk；但生态层面的代价，比前几年更大了。([GitHub][1])

**最大的收益**，本质上只有一个：你拿回了设备更完整的控制权。Magisk 官方列出的核心能力就是给应用提供 root、用模块改只读分区、以及通过 Zygisk 在应用进程里运行代码；AOSP 也明确说明，解锁 bootloader 后才能重刷镜像。对“刷第三方 ROM / 内核、做系统级调试、做深度定制、研究 Android 平台”这类事，这种权限确实是别的方案很难完全替代的。([GitHub][2])

**最大的损失**，也只有一个：你会失去“被主流生态信任”的状态。到 2026 年，很多敏感应用不只是简单查 root，而是会结合 Play Integrity 的设备完整性、Play Protect、app access risk 等信号统一判断环境是否可信。Google 官方文档里写得很清楚：在 Android 13 及以上，`MEETS_DEVICE_INTEGRITY` 要求 bootloader 处于锁定状态，且运行的是厂商认证镜像；`MEETS_STRONG_INTEGRITY` 还额外要求较新的安全更新。也就是说，**很多损失其实在你解锁 bootloader 那一刻就已经发生了，甚至还没 root 完成。** ([Android Developers][3])

落到现实里，这个损失最常见地表现为：**支付、银行、部分证券、企业办公、游戏风控、DRM 内容**更容易出问题，或者变成“这次能用，下次更新又不行”的猫鼠游戏。Google Wallet 的官方帮助页现在仍明确写着：root、custom ROM、修改过的系统、未获认证设备、以及 **unlocked bootloader** 的手机，可能无法在商店里使用 tap to pay；不满足安全要求时，不能做无接触支付。([Google Help][4])

还有一个经常被低估的损失是**安全模型和维护成本**。AOSP 官方说明里直接写了：解锁 bootloader 会触发恢复出厂设置；设备在解锁状态下，Verified Boot 会向系统报告 `orange` 状态，并在开机时提示“software integrity cannot be guaranteed”。这不是吓唬人，而是 Android 的信任链本来就被你主动放松了。后面每次大版本升级、QPR、内核变更、模块冲突、刷机失败，维护成本都在你自己身上。([Android Open Source Project][5])

所以我会把它归纳成一句话：

**root 的核心收益是“系统主权”，核心代价是“生态信任”。**

什么时候“值得 root”？通常得满足下面这种情况之一：

- 你真的要刷第三方 ROM、内核、GSI，或者自己改系统镜像。
- 你需要系统级 hook / 模块能力，而不是“有点想折腾一下”。
- 这是副机、测试机、旧机，兼容性和稳定性不是第一优先级。
- 你能接受出问题后自己救砖、回滚、重装、重新过完整性校验。([GitHub][2])

什么需求下，我会认为**最好不要 root**：

- 这是你的**主力机**。
- 你日常依赖 **Google Wallet / 银行 / 证券 / 企业工作资料 / 高 DRM 流媒体**。
- 你不能接受一次次排查“为什么这个版本突然不通过完整性检查”。
- 你手机里放很多敏感数据，或者你对设备的“默认可信状态”有要求。
- 你买的是某些运营商/地区渠道机，本身就可能不允许解锁 bootloader。AOSP 文档也写到，设备可能会因为 OEM unlock 能力没开放而拒绝 `fastboot flashing unlock`。([Google Help][4])

如果你问我一个更直白的建议：

**主力机：一般不建议 root。**
**副机、开发机、旧机：有明确目标就可以 root。**

再说得尖锐一点，2026 年去 root，已经不太像“提升体验”，更像是你在主动换一种生活方式：
你拿到更多控制权，但要自己承担更多不确定性。

你要是愿意，我可以接着按你的具体机型再给你一个更实用的判断：**什么手机现在还值得 root，什么手机 root 成本已经高到不划算。**

[1]: https://github.com/topjohnwu/Magisk/releases?utm_source=chatgpt.com "Releases · topjohnwu/Magisk - GitHub"
[2]: https://github.com/topjohnwu/Magisk?utm_source=chatgpt.com "GitHub - topjohnwu/Magisk: The Magic Mask for Android"
[3]: https://developer.android.com/google/play/integrity/verdicts "Integrity verdicts  |  Play Integrity  |  Android Developers"
[4]: https://support.google.com/wallet/answer/12200245?hl=en "Fix problems with tap to pay transactions - Google Wallet Help"
[5]: https://source.android.com/docs/core/architecture/bootloader/locking_unlocking "Lock and unlock the bootloader  |  Android Open Source Project"
```





### AVF

:::tip

AVF跟root完全是两码事

核心价值就在于可以

:::







## 结语

最开始我其实是带着一种很自然的 Nix 迁移冲动去看 Android 的。

我希望它也能被配置化，也能被记录，也能被恢复，最好还能带一点声明式的味道。

结果一路看下来之后，我发现这个问题并不是“有没有找到那个足够酷的工具”，而是：

**我一开始其实把两道题混成了一道。**

如果问题是 Android host 本体上的 App 安装与恢复，那么最后真正能落地的，只会是一个很朴素的答案：

**维护一份 App manifest，再用 ADB 把装机过程脚本化。**

如果问题是 Android 设备能不能作为开发机，那么真正值得认真看的答案，也不是继续在 Android host 本体上硬拗，而是：

**把开发环境放进 AVF guest。**

所以最后留下来的，不是“Android 也变成第三个 Nix host”。

而是一个更现实、也更准确的判断：

**Android host 和 Android guest，应该被当成两个不同的问题来处理。**

前者追求的是可重复 bootstrap。
后者才有资格谈接近 NixOS 式的环境管理。

这个结论没有最开始那个愿景那么漂亮。

但它至少让我知道，下一次如果我真的要重新配置一台 Android 设备，到底该在哪一层认真投入精力。
