---
title: linux内核参数调优
date: 2026-01-26
status: active
author: lucas
last_reviewed: 2026-01-26
related: lib/vps-nettune.nix
---

# VPS Kernel Nettune

此文档描述本仓库的“VPS 网络/内核参数动态生成”功能（Nettune）。

## 目标

Inspired by https://www.omnitt.com/

也就是 根据VPS的网络参数，来生成优化后的kernel参数

参考了如下repo:

- https://github.com/emadtoranji/NetworkOptimizer
- https://github.com/ylx2016/Linux-NetSpeed
- https://github.com/wazar/sysctl-optimizer/blob/master/auto-optimize-sysctl.sh
- https://github.com/ENGINYRING/sysctl-Generator/blob/main/sysctlgen.sh
- https://github.com/jtsang4/nettune

---

- 仅在 `nixos-vps` 主机上启用动态 sysctl 生成。
- 通过 inventory 提供少量输入参数，自动生成整套内核/网络参数。
- 统一管理：算法逻辑集中在 `lib/nettune.nix`，应用入口在 `modules/nixos/base/networking.nix`。

---

## 配置入口

- 输入参数：`inventory/nixos-vps.nix` → `nodes.<name>.hardware`
- 生成逻辑：`lib/vps-nettune.nix`
- 应用入口：`modules/nixos/base/networking.nix`

## 入参（最终版）

必需：

- `bwMbps`：有效带宽（单值，替代 local/server）
- `rttMs`：网络 RTT（毫秒）
- `memGiB`：内存大小（GiB）
- `mode`：`steady | balanced | performance | aggressive`

可选：

- `cc`：拥塞控制算法（默认 `bbr`）
- `qdisc`：队列算法（默认 `cake`）
- `cpuCores`：CPU 核心数（缺省走保守分档）

> 说明：`diskType` 不进入最小集合，默认按 SSD 假设。

## inventory 示例

```nix
{
  nodes = {
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
        qdisc = "cake";
      };
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

- `modules/nixos/base/networking.nix` 在评估时读取 inventory。
- 若当前 host 在 inventory 中存在 `hardware`，则使用 `mylib.nettune.mkSysctl` 动态生成。
- 若不存在 `hardware`，则退回 `mylib.nettune.defaults`。

## 生成逻辑概览

逻辑分三层：

1. **baseline 常量集合**
   - 来自原 `modules/nixos/base/networking.nix` 中的 server 块，整体迁移并保留注释。

2. **资源驱动项（mem/cpu）**
   - `vm.min_free_kbytes` 根据 `memGiB` 计算并钳制。
   - `net.core.somaxconn`、`net.ipv4.tcp_max_syn_backlog` 根据 `cpuCores` 计算；若未提供则用保守默认。

3. **BDP 驱动项（带宽/RTT/mode）**
   - `bufMax = round_up(BDP * factor, 4096)`
   - `factor` 和 `capPct` 由 `mode` 决定
   - `net.core.rmem_max/wmem_max` 与 `tcp_rmem/tcp_wmem` 的 max 由 `bufMax` 生成

### mode 对应策略（默认表）

| mode        | BDP 倍数 | 内存占用上限 | backlog 放大 |
| ----------- | -------: | -----------: | -----------: |
| steady      |       1x |           2% |           1x |
| balanced    |       2x |           4% |           2x |
| performance |       3x |           8% |           3x |
| aggressive  |       4x |          12% |           4x |

## 主要输出项（示意）

- kernel/vm：`panic`, `min_free_kbytes`, `overcommit_*` 等
- net.core：`rmem_max`, `wmem_max`, `somaxconn`, `netdev_max_backlog`, `default_qdisc`
- net.ipv4：`tcp_rmem`, `tcp_wmem`, `tcp_fastopen`, `tcp_mtu_probing`, `tcp_max_syn_backlog` 等

完整定义见：`lib/nettune.nix`

## 注意事项

- 动态生成仅对 `nixos-vps` 生效；其他主机仍走原有基线配置。
- `bwMbps` 必须是“有效带宽”。若运营商是共享带宽，建议填真实可用值。
- 如果不提供 `cpuCores`，并发相关参数会退回保守默认值。

## 测试

### namaka

本功能提供一个基于 Namaka/Haumea 的 eval 测试夹具，用于验证 `networking.nix` 能从 inventory 读取硬件参数并生成 sysctl。

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
