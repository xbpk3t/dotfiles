---
title: linux内核参数调优
date: 2026-01-26
status: active
author: lucas
last_reviewed: 2026-01-26
related: lib/vps-sysctl.nix
---

# VPS Kernel Nettune

此文档描述本仓库的“VPS 网络/内核参数动态生成”功能（Nettune）。

## Changelog [2026-01-26]

### defaults 迁移为 mkDefault（架构决策）

- 决策背景：`defaults` 固定集合无法表达“基线也应可被覆盖”的语义，且与动态策略并存时可读性差。
- 处理方式：移除 `defaults`，改为 `mkDefaultSysctl`（对 `mkSysctl` 的输出逐项 `mkDefault` 包装）。
- 影响与结果：无硬件输入时仍有完整基线，但优先级更低，方便后续覆写/分层扩展。
- 具体修改：`modules/nixos/vps/sysctl.nix` 作为入口，硬件缺省时回退到 `mylib.vpsSysctl.mkDefaultSysctl`。

### 动态公式覆盖（参数策略决策）

- 决策原则：只要脚本中该 key 是动态计算，就必须动态化（避免“调优名不副实”）。
- 计算输入：严格使用 `inventory.hardware` 的既有参数（`bwMbps/rttMs/memGiB/cpuCores/mode/cc/qdisc`），不新增入参。
- BDP 处理：用 `bwMbps` 近似“有效链路速率”，结合 `rttMs` 计算 BDP；buffer 上限取 “BDP 结果” 与 “速率分档下限” 的较大值。
- 速率分档：将脚本的 NIC 分档（>=10G/1G）映射到 `bwMbps` 的分档（>=10000/1000）。

### 内存与并发的动态化（关键公式决策）

- `vm.min_free_kbytes`：按 `memGiB * 4096` 并钳制（避免内存紧张时频繁抖动）。
- `kernel.pid_max / kernel.threads-max`：按内存线性放大并钳制（脚本同源逻辑）。
- `fs.file-max`：按内存线性放大并钳制（避免高并发下 fd 触顶）。
- `net.core.somaxconn / net.ipv4.tcp_max_syn_backlog`：按 CPU 线性增长并钳制（以并发能力为主导）。
- `net.netfilter.nf_conntrack_max`：按内存线性增长并钳制（避免 conntrack 表过小或膨胀失控）。

### SSD 默认策略（磁盘模型决策）

- 决策背景：不新增 `diskType` 入参，但脚本大量参数依赖磁盘类型。
- 处理方式：默认按 SSD/NVMe 处理，并在相关项上明确注释，提醒可覆盖。
- 影响项：`vm.swappiness`、`vm.dirty_ratio`、`vm.dirty_background_ratio`、`vm.vfs_cache_pressure`、`vm.dirty_*` 等。

### 全量补齐脚本参数（覆盖范围决策）

- 目标：把多个脚本里出现的 key 全部纳入（包括你原先没有列出的项）。
- 新增范围：
  - kernel：调度粒度、ASLR、dmesg 限制、perf 限制、keys/namespace 上限等。
  - vm：hugepage/THP、oom 行为、dirty/writeback 细化等。
  - net.core：busy_poll/read、netdev budget 等高并发项。
  - net.ipv4：ICMP、ARP、redirect、安全/路由相关项。
  - net.ipv6：accept\_\*、disable_ipv6、邻居表阈值等。
  - netfilter：conntrack 超时与规模控制。
  - fs：aio、inotify、nr_open、suid_dumpable 等。

### 风险点与兼容性处理（实现决策）

- 部分 sysctl 可能在旧内核不可用（如 `vm.transparent_hugepage.*`、`kernel.tsc_reliable`），明确在注释里提示“可能被忽略/失败”。
- `tcp_tw_recycle` 已废弃，明确保持 0，避免 NAT/移动网络异常。
- `qdisc` 默认设为 `fq`（脚本一致），如需 `cake` 在 inventory 覆写。

### 分组与注释强化（可维护性决策）

- 分组标题改为醒目的 `################## ... ############` 形式，便于快速定位。
- 对关键项补充中文技术注释，包含：作用（what）、原因（why）、风险点与适用场景。

## 目标

Inspired by https://www.omnitt.com/

也就是 根据VPS的网络参数，来生成优化后的kernel参数

参考了如下repo:

- https://github.com/emadtoranji/NetworkOptimizer
- https://github.com/ylx2016/Linux-NetSpeed
- https://github.com/wazar/sysctl-optimizer/blob/master/auto-optimize-sysctl.sh
- https://github.com/ENGINYRING/sysctl-Generator/blob/main/sysctlgen.sh
- https://github.com/jtsang4/nettune

:::tip

所以也可以认为该feats只是对于以上这些shell的nix化

:::

---

- 仅在 `nixos-vps` 主机上启用动态 sysctl 生成。
- 通过 inventory 提供少量输入参数，自动生成整套内核/网络参数。
- 统一管理：算法逻辑集中在 `lib/vps-sysctl.nix`，应用入口在 `modules/nixos/vps/sysctl.nix`。

---

## 配置入口

- 输入参数：`lib/inventory/data.nix` → `<host>.hardware`
- 生成逻辑：`lib/vps-sysctl.nix`
- 应用入口：`modules/nixos/vps/sysctl.nix`

## 入参（最终版）

必需：

- `bwMbps`：有效带宽（单值，替代 local/server）
- `rttMs`：网络 RTT（毫秒）
- `memGiB`：内存大小（GiB）
- `mode`：`steady | balanced | performance | aggressive`

可选：

- `cc`：拥塞控制算法（默认 `bbr`）
- `qdisc`：队列算法（默认 `fq`）
- `cpuCores`：CPU 核心数（缺省走保守分档）

> 说明：`diskType` 不进入最小集合，默认按 SSD 假设。

## inventory 示例

```nix
{
  nixos-vps-dev = {
    hostName = "nixos-vps-dev";
    primaryIp = "142.171.154.61";
    hardware = {
      bwMbps = 500;
      rttMs = 120;
      memGiB = 2;
      cpuCores = 2;
      mode = "balanced"; # steady|balanced|performance|aggressive
      cc = "bbr";
      qdisc = "fq";
    };
  };
}
```

### 如何从测评报告填写 `bwMbps` 与 `rttMs`

本仓库默认采用“Speedtest.net 行”的数据作为最直观的输入来源：

1. 在测试报告中找到 **Speedtest.net** 一行
2. `bwMbps` 取该行 **上传/下载的较小值**（四舍五入到整数）
3. `rttMs` 取该行 **延迟**（毫秒，四舍五入到整数）

示例（对应你当前两台 VPS 的报告）：

- **nixos-vps-dev（fSsML.txt）**
  https://paste.spiritlhl.net/#/show/fSsML.txt

  Speedtest.net：下载 879.84 Mbps / 上传 905.22 Mbps / 延迟 0.867 ms
  → `bwMbps = 880`，`rttMs = 1`

- **nixos-vps-svc（dhMLJ.txt）**

https://paste.spiritlhl.net/#/show/dhMLJ.txt

Speedtest.net：下载 18.88 Mbps / 上传 18.21 Mbps / 延迟 47.878 ms
→ `bwMbps = 18`，`rttMs = 48`

## 运行逻辑概览

- `modules/nixos/vps/sysctl.nix` 在评估时读取 `lib/inventory/data.nix`。
- 若当前 host 在 inventory 中存在 `hardware`，则使用 `mylib.vpsSysctl.mkSysctl` 动态生成。
- 若不存在 `hardware`，则退回 `mylib.vpsSysctl.mkDefaultSysctl`（mkDefault 包装的保守基线）。

## 生成逻辑概览

逻辑分三层（以脚本公式为主，结合本仓库已有 BDP 逻辑）：

1. **资源驱动项（mem/cpu）**
   - `kernel.pid_max`、`fs.file-max`、`vm.min_free_kbytes` 等按 `memGiB` 线性计算并钳制。
   - `net.core.somaxconn`、`net.ipv4.tcp_max_syn_backlog` 等按 `cpuCores` 线性计算并钳制。

2. **链路驱动项（bw/rtt/mode）**
   - 使用 `bwMbps` 近似有效链路速率，并结合 `rttMs` 计算 BDP。
   - `net.core.rmem_max/wmem_max` 取 “BDP 结果” 与 “速率分档下限” 的较大值。

3. **磁盘类型策略（默认 SSD）**
   - 未新增入参，默认按 SSD/NVMe 处理，并在配置上用注释标明。
   - 影响项：`vm.swappiness`、`vm.dirty_*`、`vm.vfs_cache_pressure` 等。

### mode 对应策略（默认表）

| mode        | BDP 倍数 | 内存占用上限 | backlog 放大 |
| ----------- | -------: | -----------: | -----------: |
| steady      |       1x |           2% |           1x |
| balanced    |       2x |           4% |           2x |
| performance |       3x |           8% |           3x |
| aggressive  |       4x |          12% |           4x |

## 主要输出项（示意）

- kernel/vm：`panic`, `pid_max`, `min_free_kbytes`, `overcommit_*` 等
- net.core：`rmem_max`, `wmem_max`, `somaxconn`, `netdev_max_backlog`, `default_qdisc`
- net.ipv4：`tcp_rmem`, `tcp_wmem`, `tcp_fastopen`, `tcp_mtu_probing`, `tcp_max_syn_backlog` 等
- net.ipv6 / netfilter / fs：IPv6 安全、conntrack、inotify、aio 限制等

## 分组输出（示意）

`lib/vps-sysctl.nix` 内使用更醒目的分组标题，便于快速定位：

```
################## MEMORY MANAGEMENT ############
################## NETWORK - CORE ############
################## NETWORK - TCP ############
################## NETWORK - IPV4 ############
################## NETWORK - IPV6 ############
################## NETFILTER / CONNTRACK ############
```

完整定义见：`lib/vps-sysctl.nix`

## 注意事项

- 动态生成仅对 `nixos-vps` 生效；其他主机仍走原有基线配置。
- `bwMbps` 必须是“有效带宽”。若运营商是共享带宽，建议填真实可用值。
- 如果不提供 `cpuCores`，并发相关参数会退回保守默认值。
- 默认按 SSD/NVMe 处理（未新增入参）；相关项有明确注释，可按需覆盖。

## 测试

### namaka

本功能提供一个基于 Namaka/Haumea 的 eval 测试夹具，用于验证 `modules/nixos/vps/sysctl.nix` 能从 inventory 读取硬件参数并生成 sysctl。

运行方式（在仓库根目录）：

```bash
nix flake check
```

测试夹具位置：

- `tests/fixtures/haumea/linux/nettune.nix`

### nix eval

```shell
nix eval '.#nixosConfigurations.nixos-vps-dev.config.boot.kernel.sysctl' --json | jq
```

执行后可以看到实际执行时，会产生的kernel参数

```log

➜ sysctl net.core.wmem_max
net.core.wmem_max = 1048576

➜ sysctl net.ipv4.tcp_rmem
net.ipv4.tcp_rmem = 16384       1048576 1048576

➜ sysctl net.core.default_qdisc
net.core.default_qdisc = cake

```
