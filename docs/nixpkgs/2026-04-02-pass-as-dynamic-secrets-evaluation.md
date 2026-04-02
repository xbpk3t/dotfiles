---
title: pass as `dynamic secrets` review
type: review
date: 2026-04-02
summary: 决策复盘：为何要评估 `dynamic secrets`、如何看待 `pass` 的尝试，以及当前继续依赖 `sops` 的背景
---



## TLDR

本文由两部分构成，去年 2025-11-03 前后初次尝试 pass as dynamic secrets 未果，所以就搁置了。今天清理废弃branch，看到了之前的这部分废代码，所以做个 deep into，看看是否有办法彻底处理掉，顺便做个review。


---

先说下为啥有了“用pass搭配sops来做secrets”这个想法

这个想法其实于 [10 CLI apps that have actually improved the way I work in the terminal - YouTube](https://youtu.be/EJ6uvqhKR4M?t=983) 这个视频，pass相关的操作太酷炫了。然后就想到目前sops管理secrets的一个硬伤，有很多会经常修改的sk，如果要用sops管理的话，就会很麻烦，具体来说，以下两点：

- 1、产生大量 git commit
- 2、每次修改都需要重新rebuild

总之就是很麻烦，且非常不灵活

这种情况用 `pass` 来解决不是正好吗？

***长期不动的secrets由 `sops`管理，临时使用或者经常修改的，由 `pass`管理***

并且nix对于pass的支持还不错，[passExtensions - MyNixOS](https://mynixos.com/nixpkgs/packages/passExtensions)


所以尝试探索是否可行

直接找了几个成熟方案：


- [brizzbuzz/opnix](https://github.com/brizzbuzz/opnix) 的需求，跟我差不多，但是他使用了 `1Password` 而非 `pass` 作为密钥源。所以没有直接使用该flake。
- https://github.com/vst/opsops
- https://github.com/timewave-computer/sopsidy

都不太满意

所以最终打算直接找些 `password management` 自己接进去，找了一下：

- pass [pass](https://mynixos.com/nixpkgs/package/pass)
- gopass [gopass](https://mynixos.com/nixpkgs/package/gopass)
- bitwarden-cli [bitwarden-cli](https://mynixos.com/nixpkgs/package/bitwarden-cli)
- https://github.com/timvisee/prs


最终验证了“此路不通”，也就作罢。这就是去年 2025-11-03 做的。


下面的内容则是今天一些尝试，仅作记录。



## 背景

这份文档是面向未来自己的决策复盘，而非迁移指南。我想把关于 `dynamic secrets` 的痛点、仓库约束、`pass` 尝试失败的经验，以及当前仍选 `sops` 的理由记录在一个清晰的框架里，以便下次评估时能直接回到这个起点。

目标是回答以下四个问题：

1. ***我真正想解决的痛点是什么？***
2. 这套 dotfiles 当前有哪些硬约束？
3. 为什么当时的 `pass` 方案失败了？
4. 为什么在今天的约束下，结论仍然是继续使用 `sops`？

## 我真正想要的，不是另一个密码管理器

真实的需求并不是再叠加一个密码管理器，而是让那些频繁变动、需要在多个工具之间共享的 token 维持一个轻量可用的输出路径。`secrets/default.nix` 的 `sops.secrets.<name>` 属性里定义了 `LLM_Sub2API_ice`、`API_context7`、`cf_r2_AK`、`cf_r2_SK`、`singbox_UUID` 等密钥，意味着模块期望这些 secrets 在 `sops` 应用后以独立的 plaintext 文件留在固定路径上供调用方读取。

`home/base/tui/AI/codex.nix` 和 `home/base/tui/AI/claude.nix` 在 `home.sessionVariables` 里通过 `cat ${config.sops.secrets.<name>.path}` 把这些路径所指的文件注入 Codex/Claude 的运行环境，这要求每次启动前 plaintext 文件就已经在磁盘上，不能靠交互式输入或临时剪贴板。`home/base/tui/zzz/rclone.nix` 也把 `config.sops.secrets.cf_r2_AK.path`/`cf_r2_SK.path` 交给 Cloudflare R2 remote 作为 `secrets`，因此 rclone 的同步命令同样依赖固定的路径。

`modules/nixos/vps/singbox-server.nix` 通过 `_secret` 把 `config.sops.secrets.singbox_UUID.path`、`singbox_pri_key.path`、`singbox_ID.path`、`singbox_hy2_pwd.path`、`acme_cloudflare_env.path` 绑定到 `services.sing-box.settings` 和 `security.acme.certs.<name>.environmentFile`，在 hy2 场景下还直接使用 `singbox_hy2_pwd`。这样的配置同时覆盖客户端和服务端场景，唯一的硬约束就是：所依赖的 plaintext path 必须在服务启动前就位，形成唯一的稳定 secrets path contract。

## 当前这套 dotfiles 的硬约束

所有关键流程都依赖明确定义的 plaintext path contract：session variables、`rclone` 和 `sing-box` 的配置都会通过 `config.sops.secrets.*.path` 读取文件，因此系统必须在启动前把 `sops` 解密后的提交落到这些路径上，任何交互式客户端都无法替代这个交付链。

## 为什么当时的 `pass` 方案失败了

当时的 `pass` 方案之所以在这个仓库里折戟，关键在于我把它当作 secrets delivery layer 的替代品去用，而不是把它当成用户侧通过 CLI 查询的工具：服务配置需要在启动前就有固定的 plaintext path，而 `pass` 默认不直接提供这样的交付契约，所以整个方案在开始就失了焦。

### 回顾总结

实践上，`pass` 分支没有为服务链路提供新的 delivery endpoint，也没能承接现有的 plaintext path contract，因此只要服务依赖 `config.sops.secrets.<name>.path`，整个系统就没法如期启动。

### 表层问题：实现没有收口

历史的 `pass` 分支只是把原先显式依赖 `config.sops.secrets.<name>.path` 的 `cat` 操作换成了运行时 `pass show`，但没有让服务配置或 bootstrap 脚本以一种可预期的方式等待或缓存这些 secret。rclone、Codex/Claude、sing-box 的服务仍然从固定路径读文件，`pass` 的运行时查询并没有将这些路径写回配置，也没有在 systemd 启动过程中同步 secret 到任何可被 `_secret` 绑定的文件，导致服务在期望 plaintext 即时就绪时找不到任何东西。换句话说，实现流程没有收口：用户命令行可以挡住问题，但服务启动链、部署脚本、CI job 仍然缺少最终的 secret delivery endpoint。

### 核心问题：模型不兼容

`pass` 的自然模型是一个由用户主动发起的查询 workflow，它的价值在于按需输出 secret、副本存在于 GPG store，而不是提前解密并持久放到磁盘上。这个仓库的约束是：sops 解密后的文件必须在系统配置层面以路径形式固化，以便模块直接 `cat` 或传给 `services.*.settings`。换言之，需要的是一条 secret delivery layer（在此之前 `sops` 就提供了静态 plaintext path），而不是仅在 CLI 里逐个查询的工具。把 `pass` 叠加到这个 delivery layer 里，很难绕过 path contract 的缺失。由于这个根本的模型不匹配，重写实现往往只能部分改善（比如加一段脚本把 `pass show` 输出写回路径），却又可能在 systemd/service 的 race、权限和 lifecycle 中带来新问题。

## 评估标准

- 继续满足现有的 plaintext path contract，确保 `sops` 解密后的文件能够在服务启动前稳定位于 `config.sops.secrets.*.path` 所代表的路径。
- 不能引入需要额外商业账户、托管服务或其他成本高昂的依赖，保持 dotfiles 在离线或自托管环境里的可用性。
- 与当前的 `sops`/Git 工作流兼容：如果需要更新 secret，应当可以通过同步 `sops` 文件并在 NixOS 重建时被拾起，而不是每次都依赖交互式 CLI 或无法被 CI 捕捉的外部操作。
- 维护静默可用性：session variables、rclone、sing-box 的配置都依赖服务启动时直接 `cat` 到 plaintext 文件，因此解决方案必须先把秘密 materialize 到磁盘再交给 systemd。

### opnix

按我当时读到的文档和示例，opnix 把 secret 的解密和 materialize 都安排在 activation 期间，理论上是想要的 delivery layer，对 `pass show` 这种 runtime 查询做出了替代。但在我理解里，实际运行还需要依赖 1Password 或某种 service account 来拉取 secret，也就意味着得为每台主机管理额外的托管服务账密和授权流程。相比评估标准里希望保持的纯开源 `sops` / Git 代价，这部分商业依赖目前看起来是一个无法接受的开销。

### *sopsidy*

sopsidy 依旧建立在 `sops-nix` 之上，secret 表现仍然是 `sops` 文件，authoring 体验只是借助 `rbw`/Bitwarden 等工具变得更亲切。即便如此，在我观察的实现里，它并没有取消对 git 提交或 `sops` 解密再重新构建的依赖：一旦 secret 变更，路径合同仍旧需要靠 git diff 和 Nix rebuild 来完成。它和评估标准里所要求的 workload 变化没有脱钩，因此暂时还看不到它把 delivery layer 这块真正交回 activation 期的迹象。

### opsops

opsops 关注的是帮忙生成清晰的 secret snippet 和 sops payload，提供的是一套灵活的构建块而非完整的 Nix delivery layer。按我当时的理解，它并没有处理 activation 时如何把 secret 写到 `config.sops.secrets.*.path` 之类的需求，也没有明确覆盖 service/CI 的 lifecycle。换句话说，它的价值点在于 authoring 辅助，而不是把 materialized plaintext 交付给期望的路径，因此在这套评估标准下仍显得不够成型。

## 候选排除总结

上述三个方案各有亮点，但都未能在本文记录的 constraints 下提供完整的 delivery path。opnix 好的架构方向被额外的商业依赖拖慢；sopsidy 最接近现有流程，却依旧需要 git diff/rebuild，无法直接承诺 `services.*` 的 plaintext path；opsops 虽然灵活，却尚未包装成激活时可用的 layer。因此在本文约束下，这三个候选都暂时不选用。

## 当前结论：继续使用 sops

在现有的硬约束下，sops 仍然是这一套仓库里最省心、最成熟的 delivery layer：它确保 `config.sops.secrets.*.path` 的文件在服务启动前落盘，不依赖运行时交互，也不会破坏 session variables、rclone、sing-box 等模块的启动链。即便 sops 的 git diff/rebuild 仍旧带来一定负担，这种稳定的 plaintext path contract 仍然最贴合当前基础设施，因此我们把这次决策定为“暂缓迁移”，把 sops 留在 delivery layer 的位置上，明确这份结论是暂缓而非彻底否定。

## 未来何时重新评估

重新评估的触发条件必须是明确可验证的进展，而不是模糊的希望。我们会在满足以下条件时重新考虑：

- 提供等价于 `config.*.secrets.<name>.path` 的交付契约，并保证这些路径在服务启动前已经就绪；
- 支持 headless/非交互式的 secret 获取与刷新流程，能够在 activation 期自动 materialize；
- 不再需要手写的 materializer 脚本来把 secret 写回磁盘，而是内建交付层；
- 真实覆盖仓库内的应用场景：NixOS services、home-manager session variables、rclone 风格的文件消费者、sing-box 等路径依赖；
- 能够实质性降低高频变动 secrets 带来的 git 提交与 rebuild 频率，让更新流程变得更轻量。

只有当某个方案在这些维度上都交出了实实在在的结果，并把 secret delivery 的责任真正交回 activation 期，我们才会再次讨论从 sops 迁移的必要性。

## 总结

目前的结论是继续用 sops，保持系统可用，不把暂缓决策误认为永久否定，同时把未来的触发条件清楚记录。只要条件成熟，就让这份评估成为下次重新评估的出发点。

简单来说，opsops, sopsidy, opnix 这三个工具里，opnix 是最能解决上面所说“两个痛点”的，但是他是用 `1password`的，所以排除掉。剩下的两个，sopsidy 搭配 `bitwarden-cli`，看起来都不错，但是无法解决上面所说的“两个痛点”，归根到底还是挂在 sops 里的，每次修改 bitwarden 密码之后，还是要 rebuild，那么相应的，具体修改也会被 git tracking，解决不了。
