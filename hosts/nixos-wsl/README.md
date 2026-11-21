# nixos-wsl

> 当前验证实例：厂商 PA `0cadhjae-vmez89`（Windows Server 2022）；WSL 节点
> tailnet IP `100.95.55.36`，同时写回 `hosts/nixos-wsl/meta.nix`。

Windows 上的 WSL2 NixOS host。目标不是把 WSL 做成生产机，而是：

- 验证 fleet 的 NixOS 系统配置能在 nixos-wsl 下 `nixos-rebuild`；
- 给公司里的 Windows 机器一份可复用的 WSL host 模板；
- 需要时作为 tailnet client 接入（默认不做 exit node / DERP）。

目录约定：

- `hosts/_base/nixos-wsl/`：所有 WSL host 的公共基线（common base）
- `hosts/nixos-wsl/`：当前这台厂商 PA 的 host 差异（目前只有 import base）
- `hosts/nixos-wsl/{meta,default}.nix`：由 `lib/fleet` / `lib/mkHost` 自动生成 flake 输出

这版只做**系统配置**，不挂 home-manager / home-core。需要 HM 时，在 output 的
`home-modules` 里先加最小 HM，再考虑 `home/core`。

## 前置条件

- Windows 10 22H2（19045.2311+）、Windows 11，或 Windows Server 2022
- 管理员权限
- WSL2 可用：`Microsoft-Windows-Subsystem-Linux` + `VirtualMachinePlatform` 已启用
- 固件/宿主已开启虚拟化（云 Windows VM 需要平台支持嵌套虚拟化）
- 建议 C 盘或数据盘留 30–60GB

在 PowerShell（管理员）里确认：

```powershell
wsl --version
wsl --status
wsl -l -v
Get-PSDrive C | Format-List Used,Free
```

## 安装 WSL 3.x

旧版 inbox WSL 没有 systemd。NixOS-WSL 需要带 systemd 的新版 WSL：

1. 从 <https://github.com/microsoft/WSL/releases> 下载 `wsl.<version>.x64.msi`
2. 管理员 PowerShell：

```powershell
Start-Process msiexec.exe -ArgumentList '/i "C:\path\to\wsl.msi" /qn /norestart' -Wait
wsl --version
```

3. 确认输出里有 `WSL 版本: 3.x` 和 6.x 内核。

> Windows Server 2022 没有 Microsoft Store，必须用 GitHub 的 MSI。WSL 3.x 的
> WSLC 容器能力在 Server 2022 上不在官方支持矩阵内，但普通 WSL2 发行版
> （NixOS-WSL 所需的路径）可以工作；本仓库只使用发行版/systemd，不用 WSLC。

## 导入 NixOS-WSL

从 <https://github.com/nix-community/NixOS-WSL/releases> 下载最新 `nixos.wsl`
（本仓库验证时是 `2605.7.2`，NixOS 26.05 基线）。

```powershell
New-Item -ItemType Directory -Force C:\WSL\NixOS | Out-Null
wsl --import NixOS C:\WSL\NixOS C:\path\to\nixos.wsl --version 2
wsl -d NixOS -- systemctl is-system-running
```

release 自带的 NixOS-WSL 26.05 模块可能因缺 `/bin/true` 让
`wsl-mnt-guard.service` 失败，`is-system-running` 显示 `degraded`。这是 release
的问题；切到本仓库 flake 里的新版 NixOS-WSL 模块后会补上 `/bin/true`。
如果仍失败，再检查 `systemctl --failed`。

## sops age key（首次 boot 前）

base 把用户 UID 固定为 `1001`（官方 release 的 `nixos` 用户占用 `1000`），
并把 WSL automount 的 uid 对齐到 `1001`；`/mnt/c` 上的文件会显示为 `luck` 所有。
在 WSL 里以 root 操作：

```sh
mkdir -p /home/luck/.config/sops/age
# 把 fleet 的 age key 写到 /home/luck/.config/sops/age/keys.txt
chown -R 1001:100 /home/luck
chmod 400 /home/luck/.config/sops/age/keys.txt
```

`secrets/default.nix` 用这个 key 解密 `ME_PASS_HASH` 等；`TAILSCALE_AUTH_KEY_WS`
由 `modules/nixos/infra/tailscale-client.nix` 按 `tailscale.role` 声明（同一份 sops key 解密）。
没有 key 时第一次 boot 会在 users/sops activation 阶段失败。

## 放入 dotfiles 并首次 boot

repo 必须放在 WSL 的 ext4 里（例如 `/home/luck/dotfiles`），**不要**放
`/mnt/c`，否则 Nix 构建和文件访问都会很慢。

```sh
sudo mkdir -p /home/luck/dotfiles
sudo tar -xzf /mnt/c/Users/<you>/Downloads/dotfiles.tar.gz -C /home/luck/dotfiles
sudo chown -R 1001:100 /home/luck/dotfiles

cd /home/luck/dotfiles
sudo nixos-rebuild boot --flake .#nixos-wsl
```

> 首次把默认用户从 `nixos` 改成 `luck` 时，**不要用 `switch`**。NixOS-WSL
> 上游文档明确要求用 `nixos-rebuild boot`，然后完整停/起 WSL；`switch` 可能在
> 同一个 activation 里删掉当前用户，导致默认用户状态不一致。

然后从 Windows 侧完整停/起发行版：

```powershell
wsl --shutdown
wsl -d NixOS
```

首启会（在 WSL 重新启动后）：

- 创建 `luck` 用户并设为 WSL 默认用户；
- 启动 `sshd`、`tailscaled`、`nix-daemon`；
- 生成 `/etc/wsl.conf`（systemd + default user）；
- `/mnt/c` 的文件按 uid 1001 呈现，和 `luck` 对齐。

## Tailscale

base 默认：

```nix
modules.networking.tailscale = {
  enable = true;
  exitNode = false;
};
```

使用 sops 里的 `TAILSCALE_AUTH_KEY_WS` 自动 join（key 自带 `tag:ws`）。join 后：

```sh
tailscale ip -4          # 记录 WSL 节点的 tailnet IP
tailscale status
```

把 IP 写回 `hosts/nixos-wsl/meta.nix`：

```nix
{
  # ...
  tailscale = {
    ip = "100.x.y.z";
    role = "ws";
  };
}
```

然后从 tailnet 内其它机器验证：

```sh
tailscale ping <wsl-tailnet-ip>
ssh luck@<wsl-tailnet-ip>
```

注意：

- `TAILSCALE_AUTH_KEY_WS` 是 90 天 reusable key；如果换成单次 key，第二个 WSL
  节点会 join 失败，需要在 Tailscale 控制台生成新 key 并更新 sops。
- WSL 节点和 Windows 宿主上的 Tailscale 节点是两台设备；不要给 WSL 节点开
  exit node / derper。
- `sshd` 的 authorized keys 来自 `globals.auth.adminKeys`；确认你的机器
  key 在里面。
- 受限网络/云电脑出口可能过滤 DERP。如果 `tailscale ping` 不通，先
  `tailscale netcheck`，再 `tailscale down/up` 重建 home relay；必要时在
  tailnet 配置自定义 DERP map。

## 常用 base 选项

在 `hosts/_base/nixos-wsl/default.nix` 里定义，host 可覆盖：

```nix
modules.wsl = {
  graphics.enable = false; # 开 WSLg 时改 true（会拉 mesa/llvm）
  # 注意：WSLg 的 /mnt/wslg/runtime-dir 由 WSL 以 uid 1000 创建，而 luck 固定
  # 1001；需要 WSLg 时要么改用 uid 1000，要么额外 chown runtime-dir。
  maxJobs = 2;             # 8GB 机器建议 2
  cores = 2;
};
```

其它可覆盖项：

- `modules.networking.tailscale.enable = false`：不加入 tailnet
- `modules.networking.tailscale.exitNode = true`：仅在有明确需求时
- `wsl.useWindowsDriver = true`：需要 Windows GPU 驱动时（配合 graphics）

## Windows 侧建议

`%UserProfile%\.wslconfig`：

```ini
[wsl2]
memory=5GB
processors=3
swap=2GB
```

改完 `wsl --shutdown` 再进。VHDX 放在本地 SSD；不要放网络盘。新 WSL 支持
sparse VHD 时可查 `wsl --help` 里的 `--manage --set-sparse`。

## 重启自启与平台空闲关机

Windows 重启后，Windows 侧的 Tailscale/sshd 会自启，但 WSL 发行版不会自动启动，
`wsl -l -v` 会显示 `Stopped`。需要：

- 手动：SSH 到 Windows 后执行 `wsl -d NixOS --exec /bin/true`，或直接在控制台打开 NixOS；
- 长期：创建 Windows 启动任务，例如：

  ```powershell
  schtasks /create /tn "Start NixOS WSL" `
    /tr "C:\Program Files\WSL\wsl.exe -d NixOS --exec /bin/true" `
    /sc onstart /ru Administrator /rp "<password>" /rl highest
  ```

  任务必须以注册该 WSL 发行版的用户运行；如果平台不允许保存密码，改用登录时任务或
  服务包装。

云电脑平台如果存在 idle 自动关机，需要向平台申请豁免；否则会周期性断电。Windows 侧
Tailscale/sshd 会自愈，但 WSL 里的 `nixos-wsl` 节点需要重新拉起。

## 慢网络/离线环境

如果目标机访问 GitHub/cache.nixos.org 很慢，可在构建机（有 Nix 的 Linux）上把
toplevel closure 和 flake input sources 一起导出：

```sh
nix build .#nixosConfigurations.nixos-wsl.config.system.build.toplevel
nix-store -qR ./result > system-paths.txt

nix flake archive --json \
  | jq -r '.. | .path? // empty' \
  | sort -u > input-paths.txt
for p in $(cat input-paths.txt); do nix-store -qR "$p"; done | sort -u > input-closure.txt

sort -u system-paths.txt input-closure.txt > paths.txt
nix-store --export $(cat paths.txt) | zstd -3 > nixos-wsl-store.nar.zst
```

目标机：

```sh
zstd -d -c /mnt/c/.../nixos-wsl-store.nar.zst | sudo nix-store --import
sudo nixos-rebuild boot --flake .#nixos-wsl --option substituters ''
# 已首次 boot 过、只是增量更新时用 switch
```

公司机器网络正常时不需要这一步，直接 `nixos-rebuild boot`（首启）或 `switch`
（已初始化）即可。

## 备份/回滚

- 备份整盘：`wsl --export NixOS C:\backup\nixos-wsl.tar`
- 删除发行版：`wsl --unregister NixOS`（不可恢复）
- 卸载新版 WSL：`wsl --uninstall` 或 MSI 卸载
- inbox 内核 MSI（如装过）：`msiexec /x {36EF257E-21D5-44F7-8451-07923A8C465E}`
- 不要把唯一状态放在 WSL 里：配置在 dotfiles，secrets 在 sops；机器被重置就
  按本文重建。

## 验证清单

首启用 `boot` + `wsl --shutdown`；重启后再跑下面的二次 `switch` 验证幂等。

```sh
systemctl is-system-running
systemctl --failed
id luck
hostname
systemctl is-active sshd
tailscale status
tailscale ip -4
sudo nixos-rebuild switch --flake /home/luck/dotfiles#nixos-wsl   # 二次幂等
```

再从 Windows 侧 `wsl --shutdown`，重新 `wsl -d NixOS`，确认默认用户是 `luck`，
Tailscale 和 sshd 自动恢复。

## 明确不做

- 不导入 `hosts/nixos-vps`、disko、hardware、bootloader
- 不整目录导入 `modules/nixos/kernel`（zram/sysctl/bootloader 不适用）
- 不挂 deploy-rs；WSL 内直接 `nixos-rebuild`
- 这版不挂 home-manager / home-core
