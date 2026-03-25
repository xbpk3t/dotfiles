---
title: NixOS Facter Hardware Guide
type: guide
status: active
date: 2026-03-24
updated: 2026-03-24
tags: [nix, nixos, hardware, facter]
summary: 说明本仓库如何接入 nixos-facter、它负责什么、它不负责什么，以及新主机的接入与验证方式。
---

# NixOS Facter Hardware Guide

`nixos-facter` 在这个仓库里负责“机器事实”，也就是可以从真实主机自动采集、并且适合收敛成单一数据源的硬件信息。它的目标不是扩展 inventory，也不是替代部署语义，而是把原本分散在 `hardware.nix` 里的硬件样板继续压薄。

当前仓库已经把 `nixos-facter` 接到 flake 输出、host hardware 配置和辅助库上。`nixos-homelab` 已经提交真实 `facter.json` 并作为第一台正式使用的主机，`nixos-vps` 和 `nixos-ws` 也已经具备同样的接入路径。

## 背景与目标

这个仓库本身是多主机仓库，但主机差异主要来自职责，而不是单纯来自“硬件型号不同”。`nixos-ws`、`nixos-homelab`、`nixos-vps`、`nixos-avf` 的差别，本质上更多是 role、service、network policy 和 deploy policy 的差别。

在这种结构下，引入 `nixos-facter` 的价值不在于接管整套 inventory，而在于把底层硬件事实从 host 手写配置里剥离出去。这样可以减少 `initrd`、`kernel modules`、`microcode` 这类低层样板，让 `hardware.nix` 更接近“剩余必须显式维护的安装结果与策略”。

## 职责边界

`nixos-facter` 只负责 machine facts。它适合表达 CPU、磁盘、总线、显卡、虚拟化类型、内核驱动关联等由主机本身决定的事实。

它不负责 inventory 语义。像节点角色、部署分组、网络拓扑、K3s 角色、Tailscale、Sing-box、服务编排、环境约束，这些仍然应该留在现有的 `inventory`、host modules 和 service modules 里。

它也不负责 policy config。比如 `fileSystems`、`swapDevices`、电源策略、trim 策略、显卡 userspace runtime、服务开关，这些并不是“探测到了就该直接启用”的事实，而是需要由仓库明确表达的运维决策。

这个仓库当前遵循的原则很简单：

- hardware facts 交给 `facter`
- policy items 保持显式配置
- disk layout 和安装结果继续放在 host 配置中

## 当前仓库接入方式

仓库在 [`flake.nix`](dotfiles/flake.nix) 中引入了 `nix-community/nixos-facter`，主要用途是暴露最新的 CLI。实际消费 `report` 的 NixOS module 已经在 `nixpkgs` 中提供。

仓库在 [`outputs/default.nix`](dotfiles/outputs/default.nix) 中暴露了 `.#nixos-facter` app。这样你可以在目标 NixOS 主机上直接运行 `nix run .#nixos-facter -- -o facter.json` 生成报告。

仓库在 [`lib/facter.nix`](dotfiles/lib/facter.nix) 中收敛了三件事：

- `reportPathIfExists`：只在文件存在时返回路径
- `readReport`：给 tests 或纯函数逻辑统一读取 JSON
- `reportPathForHost`：约定 `hosts/<host>/facter.json` 为每台主机的 report 路径

仓库再通过 [`lib/default.nix`](dotfiles/lib/default.nix) 暴露 `mylib.facter`，让 host 与 tests 都从同一个入口消费这套逻辑。

每台主机最终只需要在自己的 `hardware.nix` 中声明：

```nix [hosts/<host>/hardware.nix]
hardware.facter.reportPath = mylib.facter.reportPathForHost "<host>";
```

这就是当前接入的核心。`facter.json` 放在 `hosts/<host>/` 下，`hardware.nix` 只保留少量显式项，其余底层硬件事实交给 `report` 驱动。

## 当前主机状态

`nixos-homelab` 已经接入真实报告，文件位于 [`hosts/nixos-homelab/facter.json`](dotfiles/hosts/nixos-homelab/facter.json)。对应的 host 配置位于 [`hosts/nixos-homelab/hardware.nix`](dotfiles/hosts/nixos-homelab/hardware.nix)。

当前这份真实报告反映出它是一台 `x86_64-linux`、`virtualisation = none` 的实体机器，因此它非常适合作为第一台正式启用 `facter` 的主机。

`nixos-vps` 已经具备接入路径，配置位于 [`hosts/nixos-vps/hardware.nix`](dotfiles/hosts/nixos-vps/hardware.nix)。不过它原本的 `hardware.nix` 就比较薄，所以 `facter` 对它的收益更多是统一方式，而不是大幅删代码。

`nixos-ws` 也已经具备接入路径，配置位于 [`hosts/nixos-ws/hardware.nix`](dotfiles/hosts/nixos-ws/hardware.nix)。如果后续落入真实 `facter.json`，它会继续受益，因为 workstation 通常仍有更多真实硬件事实可以交给自动采集。

## 已被 Facter 替代的配置

当前接入后，以下这类“硬件事实型”样板已经不再建议手写保留：

- `boot.initrd.availableKernelModules`
- `boot.initrd.kernelModules`
- `boot.kernelModules`
- `boot.extraModulePackages`
- `hardware.cpu.*.updateMicrocode`

这次接入的重点之一，就是不再保留这些旧样板的 fallback。既然已经决定引入 `facter`，就应当把这部分职责真正收口到单一数据源，而不是继续同时维护两套来源。

## 仍需显式维护的配置

`facter` 不是“所有硬件相关内容都自动接管”。下面这些仍然应该由仓库显式维护，因为它们要么属于安装结果，要么属于策略决策。

### Disk Layout 与安装结果

`fileSystems` 和 `swapDevices` 仍然保留在 host 配置中。它们更接近安装后的事实表达和运维约束，不适合因为一次硬件扫描就自动漂移。

### 通用运行策略

像 `services.fstrim.enable` 这种选项虽然和硬件相关，但本质上是 policy，而不是 machine fact。仓库当前继续显式保留它，而不是交给泛化的 profile 或自动探测。

### Laptop Power Policy

`services.tlp.enable` 和 `services.power-profiles-daemon.enable` 也仍然应该显式写在 host 上。它们表达的是 power management policy，不是 `facter` 应该替你决定的事实。

### Graphics User-space Runtime

像 Intel iGPU 的 `intel-media-driver`、`intel-compute-runtime`、`vpl-gpu-rt` 这类 `hardware.graphics.extraPackages`，仍然应该显式保留。`facter` 能告诉你机器上有什么 GPU，但它不会替你决定 userspace media runtime 应该如何组合。

这也是这次清理 `nixos-hardware` 通用 import 的一个原则：把真正需要的运行时语义写回 host，而不是继续藏在宽泛的 profile 里。

## 新主机接入流程

先在目标主机上生成 report。优先使用仓库已经暴露出来的 app：

```bash
sudo nix run '.#nixos-facter' -- -o facter.json
```

如果当前目录不是这个仓库，或者远端没有直接使用本仓库 flake，也可以使用：

```bash
sudo nix run 'nixpkgs#nixos-facter' -- -o facter.json
```

生成后，把文件提交到对应主机目录：

```text
hosts/<host>/facter.json
```

然后在该主机的 `hardware.nix` 中把 `hardware.facter.reportPath` 指向这个文件。对于新 host，推荐沿用现有模式，直接调用 `mylib.facter.reportPathForHost "<host>"`。

最后，检查是否还有可以继续删除的“硬件事实型样板”。如果某项只是历史上因为 `nixos-generate-config` 或 `nixos-hardware` profile 带来的底层样板，就应优先考虑删掉；如果某项属于运行策略，就保留为显式配置。

## 验证方式

最直接的验证是先看 `reportPath` 是否被正确解析：

```bash
nix eval .#nixosConfigurations.<host>.config.hardware.facter.reportPath
```

如果这里能得到一个 store path，说明该 host 已经正确把 `facter.json` 接入到 NixOS 配置评估链路中。

第二层验证是运行：

```bash
nix flake check --keep-going
```

这会覆盖仓库的常规检查流程，也是当前最值得信任的整体验收入口。

仓库里还保留了一层与 `facter` 辅助逻辑相关的 `Namaka` fixture 测试，示例位于 [`tests/fixtures/haumea/linux/facter.nix`](dotfiles/tests/fixtures/haumea/linux/facter.nix)。这类测试适合验证 `mylib.facter.readReport`、`reportPathIfExists` 之类的纯函数逻辑是否稳定。

不过，对这次接入来说，`Namaka` 更适合做 helper 层的回归保护，而不是替代 host 级验收。真正决定“这台机器能不能正常消费 report”的，仍然是 `nix eval` 和 `nix flake check`。

## 维护建议

当出现以下情况时，你应该重新生成并更新对应主机的 `facter.json`：

- 更换实体机器
- 变更主要硬件
- 发生显著平台变化
- 首次把某台旧主机接入 `facter`

不要把 `facter` 当成 inventory 替代品。它负责的是机器事实，不负责仓库中的角色、拓扑、部署语义和服务策略。

如果某台主机本来 `hardware.nix` 就非常薄，例如纯云 VPS，那么接入 `facter` 的主要收益是统一模型，而不是显著减少代码量。相反，对于 workstation、laptop、homelab 这类真实硬件更复杂的节点，`facter` 往往更值得使用。
