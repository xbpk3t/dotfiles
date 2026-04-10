---
title: nix-darwin配置优化记录
type: review
status: active
date: 2025-09-17
updated: 2025-09-17
isOriginal: true
tags: [nix, darwin]
---

## shell 脚本里的 `~`

- 在 shell 脚本中，`~` 不会自动展开，需要使用 `$HOME`。

## `rclone` 日志参数

- 使用rclone的-verbose 和 --progress会打出来太多东西了，在log里想查看日志格式的执行记录，参数用啥？

## nix 多用户、多 distro 场景

**_nix 多用户 多distro 场景 “给mac新创建一个luck用户。然后重新跑整套nix配置。需要在此之前先把手头这些文件处理掉。”。_**

经典问题了，最终方案就是把username直接写死。中间尝试了直接从ENV里读取（因为可以从`nix eval --impure --expr 'builtins.getEnv "USER"'`，就以为），但是这里存在一个先后顺序，MAIL可以这么处理是因为只在git.nix中使用，此时已经evaluate完成了，成功获取相应val，但是username则在home-manager中使用，在evaluate之前，所以不能从ENV里读取，只能设置为常量。另外，这里也适用specialArgs 简化配置。

## 更新频率

- 【flake包更新频率（nix flake update）】、【Nix 包管理器 更新频率（nix upgrade-nix）】前者每周1-2次，因为本身更新比较频繁。后者每月一次。

## `--dangerously-skip-permissions`

之后开始玩cc，直接使用--dangerously-skip-permissions，相较于手动维护 permissions -> allow，还需要频繁自己点击accept按钮，就简单多了。

这里需要注意的是如果开启该flag之后，所有权限检查（allow、deny、ask）都会被跳过。这里还带来两个问题：

- 1、怎么评价GLM模型？
- 2、

---

## 把之前用 `systemPackages` 管理的 pkg 全都用 hm 管理了

具体执行分为两步：

- 1、拿所有我的pkg跟hm的所有pkg取交集，所有hm支持的pkg全部又hm管理，做配置。
- 2、即使hm不支持配置项的pkg，就直接放到home/default.nix里，同样由home管理（但不做配置）。

## `systemPackages` 还是 hm

对于nix来说，放在 systemPackages 还是 home-manager，是否其实没有太大区别？还是说实际上区别很大？是否会影响disk占用之类的？我的意思是，我的MBP物理机就是我一个人使用。是不是其实没啥区别？你更推荐我放在 hm还是system?

【结论】包存储层面（Disk占用）没有任何区别，对nix来说，都是对于/nix/store的ln。二者的区别就在于systemPackages是全局安装，所有用户都能使用，hm则是用户级安装，只有指定用户可用。那么相应的，从环境变量来说，systemPackages安装的pkg出现在系统的 PATH 中，hm则出现在该用户的PATH中。

由此可以推论，如果只是个人使用确实没有任何区别，但是从可维护性来说，更推荐hm。基于以下原因：

- 1、更好的隔离性（避免系统级配置污染）。
- 2、更容易迁移（hm配置可以轻松迁移到其他机器）。
- 3、回滚更安全（用户级配置的回滚不会影响系统稳定性）。
- 4、更精细的配置（很多工具的配置更适合在用户级别管理）。

<details>
<summary>services vs hm</summary>

<img width="1768" height="5006" alt="Image" src="https://github.com/user-attachments/assets/d00eede3-c4bd-42af-93a9-e9e3949f0330" />

</details>

---

## `bash.nix` 里的这些 pkg

bash.nix里的这些pkg，为啥只要开启enableBashIntegration配置项，就可以自动集成到bash里，具体是怎么实现的？（注意atuin、bat、fd其实没有做bash集成，只不过，真正做了的是）

## 【stylix】学到的几个点

- 1、开启autoEnable之后，会自动处理可用pkg，不需要再在targets里定义这些pkg。
- 2、这里还遇到一个font的坑，。
- 3、【关于stylix的工作机制】？可以理解为类似 代码设计里控制反转和依赖注入的感觉。这些组件本身就有theme这个配置，stylix则相当于一个集中管理，那么毫无疑问的，首先stylix需要确认有哪些targets可供使用，然后把按照不同组件的配置，根据stylix本身的配置，给这些组件生成各自的theme配置文件，然后ln到相应组件的config路径下。

另外，这里还有个小问题，如果配置类似`stylix.targets.yazi.enable = true`这样的配置，会报 key not exist，然后build失败。不过既然能用，所以暂时搁置。

---

## 【Nix-Darwin】今天处理的内容

这个就是今天处理的了，今天仔细研究了一下nix-darwin的文档，完成了以下工作：

【hosts和modules】到底应该把配置放在哪个里面？

这里的归根到底就是要把握 变与不变，经常修改或者因人而异的，放到hosts里，基本上不修改的，放到 modules/darwin 里。另外，可以在modules的配置项添加`lib.mkDefault`作为默认值，这样就可以在hosts里overrides掉这些默认值（这里需要注意的是，hosts里需要注意先后顺序，我之前的配置就犯了这个错，应该import modules在上面，hosts的配置在下面。否则就变成了你hosts里的配置被modules里的overrides了）

---

【补充了之前没有配置的nix-darwin配置项】这里首先需要甄别几组关系：

- 1、【nix-darwin 和 home-manager 的区别】比如同样是ssh，`home-manager/options/programs.ssh` 和`nix-darwin/options/programs.ssh`都有。但是配置项不同，你觉得实际上有啥区别？很简单，nd是系统及，hm是用户级。但是需要注意的是，如果已经在hm里配置了相应配置，其实不需要在nix-darwin里再配置（这点跟上面第7点是类似的）。
- 2、包括 fonts（这里需要注意的是，AI说应用stylix管理fonts而非nd提供的fonts，这个说法就有问题，实际上这里的fonts指的是macos本身的自定义字体（也就是 Font Book.app里的 My Fonts。注意只是自定义字体，而非macos本身的内置字体）。我只添加了几个真正需要的，尽量保持精简）、networking、power、security、system（大部分是从之前hosts里挪过来的，也新增了很多，可能是nd里最有用的option了）

---

- 3、【配置重复问题】类似第1条，移除了hosts和modules里的重复配置。所有配置都做到modules里，如果需要overrides，才在hosts里添加相应配置。
- 4、【bash的环境变量问题】今天下午玩CCR发现`pnpm install -g`会报错.解决掉bash的PATH问题，应该使用 home.sessionPath 配置，而非配置在 home.sessionVariables里。否则无法展开也就无法应用。

<details>
<summary>NixOS vs nix-darwin</summary>

<img width="835" height="3853" alt="Image" src="https://github.com/user-attachments/assets/ddd9b473-2b79-40e0-82db-663908b24ead" />

<img width="877" height="4090" alt="Image" src="https://github.com/user-attachments/assets/b7ba5315-b49d-4164-8489-ed266e3f38a2" />

</details>

## 总结

从上周五搞到今天（周三），确实对nix建立了很多新认知，所以记录也写的比较多。
