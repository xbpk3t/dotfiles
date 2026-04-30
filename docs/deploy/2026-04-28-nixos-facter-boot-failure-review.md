---
title: nixos-facter VPS 启动失败复盘
type: review
isOriginal: true
date: 2026-04-28
tags: [nixos, facter, vps, boot, postmortem]
---


:::tip[TLDR]

***放在公司里算是P0事故了，对个人也算是事故了。自己现有的两台VPS在reboot之后直接挂掉了，连系统都进不去。***

此事从何而起呢？

又是怎么发现真正问题所在呢？

以后怎么避免类似问题呢？


---

[nixos-factor.md](../nix-tools/2026-03-24-nixos-facter.md)


:::






## 事故概要

当时在处理 `.taskfile/network` 里面的那些 `taskfile.yml`，因为很多工具在 darwin 不支持，所以打算安装到 linux机器上，所以对 `nixos-vps` 做了rebuild


具体 rebuild log 如下

```markdown
~/Desktop/dotfiles  main [$✘»!+⇡] via  v24.14.1
➜ task nix:deploy
warning: Git tree '/Users/luck/Desktop/dotfiles' has uncommitted changes
task: [nix:deploy:default] if [[ -z "nixos-vps-dev
nixos-vps-svc" ]]; then
  echo "No node selected"
  exit 1
fi
# NOTE: xargs 在 -I 模式下会按行逐个替换，-n1 与其冲突且会触发 warning。
printf "%s\n" "nixos-vps-dev
nixos-vps-svc" | xargs -P "4" -I{} \
  nix run --impure .#deploy-rs -- --skip-checks ".#{}" -- --impure

warning: Git tree '/Users/luck/Desktop/dotfiles' has uncommitted changes
warning: Git tree '/Users/luck/Desktop/dotfiles' has uncommitted changes
🚀 ℹ️ [deploy] [INFO] Evaluating flake in .
🚀 ℹ️ [deploy] [INFO] Evaluating flake in .
warning: Git tree '/Users/luck/Desktop/dotfiles' has uncommitted changes
warning: Git tree '/Users/luck/Desktop/dotfiles' has uncommitted changes
warning: Using 'builtins.derivation' to create a derivation named 'options.json' that references the store path '/nix/store/jzd9vz08h5b7s3rgxzpw28mpw4rxk2ra-source' without a proper context. The resulting derivation will not have a correct store reference, so this is unreliable and may stop working in the future.
warning: Using 'builtins.derivation' to create a derivation named 'options.json' that references the store path '/nix/store/jzd9vz08h5b7s3rgxzpw28mpw4rxk2ra-source' without a proper context. The resulting derivation will not have a correct store reference, so this is unreliable and may stop working in the future.
🚀 ℹ️ [deploy] [INFO] The following profiles are going to be deployed:
[nixos-vps-svc.system]
user = "root"
ssh_user = "root"
path = "/nix/store/f7pgll433iq640va8m3m4wq3r0np2b74-activatable-nixos-system-nixos-vps-svc-26.05.20260423.01fbdee"
hostname = "103.85.224.63"
ssh_opts = []

🚀 ℹ️ [deploy] [INFO] The following profiles are going to be deployed:
[nixos-vps-dev.system]
user = "root"
ssh_user = "root"
path = "/nix/store/qhp33nkacn0lcbkjh2d5x0r8b6b797sa-activatable-nixos-system-nixos-vps-dev-26.05.20260423.01fbdee"
hostname = "142.171.154.61"
ssh_opts = []

🚀 ℹ️ [deploy] [INFO] Building profile `system` for node `nixos-vps-svc` on remote host
🚀 ℹ️ [deploy] [INFO] Building profile `system` for node `nixos-vps-dev` on remote host
🚀 ℹ️ [deploy] [INFO] Activating profile `system` for node `nixos-vps-svc`
🚀 ℹ️ [deploy] [INFO] Creating activation waiter
👀 ℹ️ [wait] [INFO] Waiting for confirmation event...
There are changes to critical components of the system:

dbus-implementation : dbus -> broker

Switching into this system is not recommended.
You probably want to run 'nixos-rebuild boot' and reboot your system instead.

If you really want to switch into this configuration directly, then
you can set NIXOS_NO_CHECK=1 to ignore pre-switch checks.

WARNING: doing so might cause the switch to fail or your system to become unstable.

Pre-switch check 'switchInhibitors' failed
Pre-switch checks failed
⭐ ⚠️ [activate] [WARN] De-activating due to error
switching profile from version 45 to 44
⭐ ⚠️ [activate] [WARN] Removing generation by ID 45
⭐ ℹ️ [activate] [INFO] Attempting to re-activate the last generation
Checking switch inhibitors... done
🚀 ❌ [deploy] [ERROR] Activating over SSH resulted in a bad exit code: Some(1)
🚀 ℹ️ [deploy] [INFO] Revoking previous deploys
🚀 ❌ [deploy] [ERROR] Deployment to node nixos-vps-svc failed, rolled back to previous generation
[3/304/368 built, 3/993/1000 copied (8378.8/8632.0 MiB), 2357.4/2364.1 MiB DL] building unit-systemd👀 ❌ [wait] [ERROR] Error waiting for activation: Timeout elapsed for confirmation
🚀 ℹ️ [deploy] [INFO] Activating profile `system` for node `nixos-vps-dev`
🚀 ℹ️ [deploy] [INFO] Creating activation waiter
👀 ℹ️ [wait] [INFO] Waiting for confirmation event...
⭐ ℹ️ [activate] [INFO] Activating profile
Checking switch inhibitors...
There are changes to critical components of the system:

dbus-implementation : dbus -> broker

Switching into this system is not recommended.
You probably want to run 'nixos-rebuild boot' and reboot your system instead.

If you really want to switch into this configuration directly, then
you can set NIXOS_NO_CHECK=1 to ignore pre-switch checks.

WARNING: doing so might cause the switch to fail or your system to become unstable.

Pre-switch check 'switchInhibitors' failed
Pre-switch checks failed
⭐ ⚠️ [activate] [WARN] De-activating due to error
switching profile from version 46 to 45
⭐ ⚠️ [activate] [WARN] Removing generation by ID 46
removing profile version 46
⭐ ℹ️ [activate] [INFO] Attempting to re-activate the last generation
Checking switch inhibitors... done
updating GRUB 2 menu...
activating the configuration...
setting up /etc...
sops-install-secrets: Imported /etc/ssh/ssh_host_rsa_key as GPG key with fingerprint f0f623063776f4b312766dbffe1709314db88f1d
reloading user units for root...
restarting sysinit-reactivation.target
⭐ ❌ [activate] [ERROR] The activation script resulted in a bad exit code: Some(1)
🚀 ❌ [deploy] [ERROR] Activating over SSH resulted in a bad exit code: Some(1)
🚀 ℹ️ [deploy] [INFO] Revoking previous deploys
🚀 ❌ [deploy] [ERROR] Deployment to node nixos-vps-dev failed, rolled back to previous generation
task: Failed to run task "nix:deploy:default": exit status 123
```

可以看到失败了

核心问题在于 `dbus-implementation : dbus -> broker` 需要 reboot 才能生效


> 当前 nixpkgs 更新后默认 DBus 实现从 dbus 变成了 dbus-broker，NixOS 认为这是 critical
component change，不允许普通 switch 直接切过去。deploy-rs --skip-checks 只跳过 deploy-rs 自己的
checks，不会跳过 NixOS activation 的 switchInhibitors。


所以此时让 GPT继续执行

```markdown

• Both nodes are now staged for next boot. I’m going to issue reboots and then wait for SSH to come
  back before checking the actual running generation.

• Ran ssh -o BatchMode=yes -o ConnectTimeout=8 root@103.85.224.63 'systemctl reboot'
  └ (no output)

• Ran ssh -o BatchMode=yes -o ConnectTimeout=8 root@142.171.154.61 'systemctl reboot'
  └ (no output)

```

***直接把机器reboot了，确实没错，但也就此铸下大错***

当时还想着reboot回来看下这些 network相关pkgs是否可用了，结果就发现梯子掉了，目标vps的SSH也连不上去


所以当时误判了，以为是

> “两个问题叠加到一起，导致 reboot之后，机器全部挂掉了”



之后尝试通过各自云服务平台的VNC进行恢复，无非是那个丝滑小连招。

「点击“发送 Ctrl+Alt+Del”按钮」 -> 「按 esc 打断」 -> 「选择之前可用的generation」

但是始终都会卡在这步

```log
A start job is running for /dev/disk/by-label/NIXOS_ROOT
```

然后就根据 DeepSeek 给出的方案（比如）尝试解决。

当然，这里还有个小插曲，本来是要先处理 racknerd 的，但因为 nerdvm 密码忘了，找回也收不到邮件，当时也没想道直接去发工单解决，所以转而去先处理狐蒂云的机器（其实也因为机器挂掉之后，没有自建机器了，无法翻墙，而我的 outlook 做了对 gmail的自动转发，翻不了墙，也就无法登录gmail，也就无法看到 nerdvm 密码），处理过程中就发现狐蒂云的VNC可能存在“吞键问题”（GRUB 的键盘输入被 VNC 吞掉，在boot阶段无法收到指令），当时已经挺晚了（因为本身就是晚上8、9点出的事故），所以决定先去睡觉。

第二天早上（也就是今早）在尝试解决问题还是直接重装之间，最终还是决定尝试解决（因为上面有部分数据，还是不想直接丢掉，虽然有nix配置，直接重装其实也很方便）。所以发了 racknerd 工单，拿到了 nerdvm 密码，进入VNC，选择了之前的generation，***然后就发现之前满心以为绝对可用的 previous generation，其实也不可用（仍然卡在上面的 NIXOS_ROOT 这步）。此时心知肯定是有些地方出问题了。***

之后按照 DeepSeek 给出的方案，选择之前的generation，按e编辑，“找到linux行，在末尾添加 `init=/bin/sh` 并将 `root=PARTLABEL=NIXOS_ROOT` 改为 `root=/dev/vda1` ，然后按F10启动”

尝试后发现仍然会报上面的

```log
A start job is running for /dev/disk/by-label/NIXOS_ROOT
```

***此时才确定肯定不是我上面推测的问题了，也就终于决定了直接重装好了***

然后掏出来之前写的 `Taskfile.nixos-anywhere.yml`

心想爽了，之前这玩意没白写，也算是派上用场了

结果发现各种问题，压根不可用啊，各种问题（比如说需要多次输入vps的密码，总之这种复杂脚本不如直接用nushell维护，只留给taskfile一个入口即可），所以改成了现在的 nushell 版本（此处不多说）

通过该命令

```shell
tgg nix:nixos-anywhere FLAKE='/Users/luck/Desktop/dotfiles#nixos-vps-dev' HOST='root@142.171.154.61' DRY_RUN=false
```

来重装 NixOS

然后就发现即使重装之后，仍然有上面的报错

让 DeepSeek-V4P 帮我来排查这个问题，瞬间我就想到是否有可能是之前 `nixos-factor` 的问题



## RCA实际根因

**并非 generation 问题，而是 `nixos-facter` 重构导致 initrd 缺少磁盘驱动。**

[refactor(hardware): 接入 nixos-facter 并收敛主机 hardware配置 · xbpk3t/dotfiles@46d3be2](https://github.com/xbpk3t/dotfiles/commit/46d3be2dc34f0bc840d90bcd1b5a88d806014a73)
将 `hosts/nixos-vps/hardware.nix` 中的手写 initrd kernel modules 全部删除，改为：

```nix
hardware.facter.reportPath = mylib.facter.reportPathForHost "nixos-vps";
```

但 `hosts/nixos-vps/facter.json` **不存在**。`mylib.facter.reportPathForHost` 返回 `null`，
nixos-facter 模块空转，**没有注入任何内核模块**。

结果：
- initrd 缺少 `virtio_blk`、`virtio_pci` 等 virtio 驱动
- 内核找不到磁盘设备 `/dev/vda`
- `/dev/disk/by-partlabel/NIXOS_ROOT` 永远不会出现
- systemd 等待根分区挂载 → 超时 → boot 卡死

### 故障链路

```
deploy-rs switch (dbus inhibitor)
  └─ reboot
       └─ 启动新 generation
            └─ initrd 无 virtio_blk → 找不到磁盘
                 └─ systemd 等待 by-partlabel/NIXOS_ROOT → boot 卡死
```

## 为什么最开始被误诊

1. **hubu.cloud（狐蒂云）的 VNC 误导**：其 VNC 控制台在 reboot 后无法主动选择 generation，
   让人误以为是"latest generation 必挂，旧 generation 也进不去"。
   但实际上 racknerd 的 VNC 是可以选 generation 的，选择旧 generation 后同样卡住，
   说明问题不在 generation 本身，而在所有 generation 共享的 initrd。

2. **时间巧合**：dbus 的 switch inhibitor 刚好发生在同一次 deploy，容易让人以为是
   dbus-broker 切换导致的系统不稳定。

## 相关文件

- `hosts/nixos-vps/hardware.nix` — 最初被 facter 重构修改的文件
- `hosts/nixos-vps/disko.nix` — disko 分区配置（本身没问题）
- `lib/facter.nix` — facter helper，文件不存在时返回 null
- `flake.nix` — 引入了 nixos-facter 的 flake input

## 教训

### 1. ***facter 对 VPS 的收益为负***

VPS 的硬件是虚拟化层固定的（virtio），hardware.nix 本来只有 ~10 行样板。
facter 引入了一个隐式依赖：`facter.json` 缺失时不会报错，只是静默地不注入驱动。
**对 VPS 来说，手写 virtio 模块比依赖自动采集更可靠。**

### 2. "硬件事实型配置"决策树

```
主机是 VPS / 虚拟化环境吗？
  ├─ 是 → 手写 initrd kernel modules，不用 facter
  └─ 否（物理机/复杂硬件）
       └─ facter.json 存在吗？
            ├─ 是 → 可用 facter，删除手写样板
            └─ 否 → 先跑 nixos-facter 生成 report，再切换
```

### 3. facter 重构不该一刀切

2026-03-24 的 record 已经判断过：

> *"nixos-vps 原本的 hardware.nix 就比较薄，facter 对它的收益更多是统一方式，而不是大幅删代码"*

> *"如果某台主机 hardware.nix 非常薄，例如纯云 VPS，接入 facter 的主要收益是统一模型，而不是显著减少代码量"*

但重构时对 nixos-homelab、nixos-vps、nixos-ws 统一做了同样的改动，
没有区分物理机和 VPS 的风险差异。

### 4. initrd 驱动缺失的验证方式

如果能 SSH 进 kexec 环境或 recovery shell：

```bash
# 检查 initrd 包含哪些内核模块
lsinitrd /boot/initrd | grep virtio
# 预期输出应包含 virtio_blk、virtio_pci、virtio_scsi 等
```

## 当前修复

恢复 VPS 的手写 initrd kernel modules：

```nix
boot.initrd.availableKernelModules = [
  "virtio_pci" "virtio_blk" "virtio_scsi"
  "ahci" "xhci_pci" "sd_mod"
];
boot.initrd.kernelModules = ["virtio_net"];
```

## 后续建议

- VPS 类主机（nixos-vps-dev, nixos-vps-svc, nixos-avf）→ 不用 facter，手写 virtio
- 物理机（nixos-homelab, nixos-ws）→ 继续用 facter
- facter 接入应在目标机上先跑 `nix run .#nixos-facter` 生成 report，确认后再切换配置



## 结论：经验总结

这里将对上面所有卡点，做个梳理。我不想写类似以下这种东西


```markdown
1. **虚拟化环境硬件配置应追求极简与确定性**
   VPS 的硬件驱动集合是固定的（virtio），手写 3 个模块的成本为零，但引入 nixos-facter 后形成了对 `facter.json` 的隐式依赖。这种依赖在文件缺失时**不报错、不警告**，直接导致 initrd 驱动缺失。对云主机而言，显式声明比“自动采集”更可靠。

2. **基础设施代码的变更必须经过目标环境验证**
   本次重构如果先在任意一台 VPS 上执行 `nixos-rebuild boot && reboot` 验证引导，故障本可避免。哪怕只是检查 `lsinitrd | grep virtio`，也能在 10 秒内暴露问题。**部署流水线缺少对 initrd 内核模块的冒烟测试**。

3. **事故排查中要警惕“共因混淆”**
   两台 VPS 在 reboot 后同时挂掉，且旧 generation 同样不可用，这强烈暗示问题不在 generation 切换，而在更底层的共享组件。但首次诊断被 dbus inhibitor 和 VNC 吞键干扰，延误了定位。今后类似场景应优先检查 **所有 generation 共用的 initrd 和内核**，而非纠结 activation 日志。

4. **恢复手段要提前准备，不能依赖单一 VNC**
   狐蒂云 VNC 的吞键问题导致无法进入 GRUB 菜单，极大延长了恢复时间。有条件时应配置串口控制台、API 接口强制重启到恢复模式，甚至准备远程 nixos-anywhere 重装脚本（本次已派上用场）。

5. **nixos-facter 的推行边界要明确**
   决策并非“是否用 facter”，而是“用在哪里”。物理机、笔记本等复杂硬件适合 facter；但所有 VPS 和单一硬件规格的主机，**禁止使用 facter 管理 initrd 驱动**，手写样板即为最终方案。

**一句话总结**：自动化引入新抽象时，如果缺少失败可见性（missing report 不报错），且绕过已有验证（reboot 前不检查 initrd），那么它带来的风险会远大于收益。
```


***其实归根到底，问题在于之前对于 `nixos-factor` 没有真正close掉***

[nixos-factor.md](../nix-tools/2026-03-24-nixos-facter.md) 是之前的处理过程

之前也有点太求全责备了，想要全部hosts的metadata都由 `nixos-factor`管理。

没想清楚，其实对于`nixos-factor`来说，真正有收益的只有宿主机，对于VPS来说，只会更麻烦，负收益。

---

除此之外还有一些问题：

- 1、
