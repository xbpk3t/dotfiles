---
role: atom
desc: nixos-anywhere VPS 刷机 runbook：磁盘/阶段/closure/构建/首启验收/失败恢复；入口固定为 task nix:nixos-anywhere
---

## What

### Is
把一台 Ubuntu（或已进入 kexec installer）的 VPS 刷成 NixOS，并完成首次 deploy。只做刷机流程的决策与执行；host 配置由仓库既有模块负责。

### Is not
不替代 Taskfile/脚本里的确定性检查；不评审 host 配置；不处理物理机/USB 刷机。

## Constraints

### Must
1. 先读 flake.nix、Taskfile、nixos-anywhere 脚本和目标 host 的 default/home/disko/hardware 配置，再动手。
2. 刷机前必须确认 DISK 与 disko.nix 一致，并量 closure size；>1.7G 必须 system-only，再用 deploy-rs 推 home。
3. 刷机后必须先 accept host key，再跑 deploy-rs。
4. 临时改过的 builder/target nix.conf 必须在收尾恢复。

### Must not
1. 不要在未确认目标机阶段、磁盘型号/序列号和 disko 配置前执行 disko。
2. 不要用 nixos-facter 管 VPS initrd；保留手写 virtio 模块。
3. 不要在未经用户确认时执行部署命令。
4. 不要把 --skip-checks 当成跳过 NixOS switchInhibitors。
5. 不要把 path: 当作绕过脏工作区的默认手段：它会把 untracked/ignored/.git 拷入 world-readable nix store。

## Workflow

### Read Entry
1. 读 flake.nix、.taskfile/nix/Taskfile.nixos-anywhere.yml、.taskfile/nix/scripts/nixos-anywhere.nu、hosts/<group>/<node>/{meta,default,home,disko,hardware}.nix、secrets/default.nix、.sops.yaml、lib/mkHost.nix。
2. 确认 `.#nixosConfigurations.<NODE>` 存在且 eval 通过（`nix eval --impure --raw .#nixosConfigurations.<NODE>.config.system.build.toplevel.drvPath`）；确认 flake.lock 已提交；确认 Linear issue 范围与验收项。不要自建 bootstrap host 或临时 flake。

### Preflight
1. 目标机重装过先 `ssh-keygen -R <IP>`；先 `ssh-copy-id`；脚本的远端 preflight 会检查 sudo/Linux/arch/setsid/kexec/disk/RAM。非 22 端口或代理先手动验证。
2. 从 disko.nix 读目标盘（默认 /dev/vda），通过 `DISK=<device>` 传给 Taskfile；核对型号/序列号，确认不是另一台机器的盘。
3. 阶段分支：Ubuntu/Debian → 默认 kexec；已是 nixos-installer → 不重复 kexec，HOST=root@<IP> 且 `PHASES=disko,install`（需要自动 reboot 才加 reboot）；非 Linux / 无 passwordless sudo / setsid 无 --wait → 停止先修前置。
4. macOS 先确认 Linux builder 可用，再 build：`nix config show | grep -E 'builders|require-sigs|trusted-public-keys|substituters'`（Mac 和 builder 都看）；`--build-on local --option builders-use-substitutes true`。临时放宽 require-sigs 后必须恢复。

### Key And Flake
1. age key 用能解密目标 secrets 的那把；Mac 上是 ~/Library/Application Support/sops/age/keys.txt（age10pr...），不要用历史遗留的 age1at...。用 `age-keygen -y <key>` 的公钥核对 `secrets/secrets.yaml` 里的 age recipient；不要用 `sops -d` 验证（会回退到默认 key）。
2. 用 AGE_KEY=...（Taskfile）让脚本注入；脚本内部对应 --age-key，并 `--chown home/luck 1000:100`，避免 /home/luck root 所有导致 HM 激活失败。
3. 确认 root 和 luck 的 SSH 公钥都在 fleet keys 中，避免关密码登录后自锁。
4. 未 commit 就先 commit（untracked 不可见）；`--store-paths` 只绕过 flake，不解决可见性。

### Closure Gate
1. 构建并量完整配置：`nix build --impure --no-link --print-out-paths .#nixosConfigurations.<NODE>.config.system.build.toplevel | xargs nix path-info -S`。
2. ≤1.7G：直接刷完整配置。>1.7G：先刷 system-only：临时把 `hosts/<group>/<node>/home.nix` 改名为 `home.nix.disabled`（mkHost 会省略 HM），commit、构建/量 closure、刷机；刷完恢复并 commit。
3. installer 的 /nix/store 是内存 overlay（≈目标 RAM；4G 机器约 2G），不是目标盘；2G RAM 机器阈值更低。**不要先验地加 `--no-disko-deps`**：先确认 installer 里有 `sgdisk`/`mkfs.ext4`/`mkfs.vfat`/`mkswap`/`partprobe`。本仓实测 nixos-images 25.05 kexec installer 没有这些工具，必须上传标准 disko 依赖（实测 356MB）。1GB 机器用 `STAGED=true`：kexec 后启用旧 swap，再 disko,install。
4. `--no-substitute-on-destination` 只改变谁下载 closure，不降低 RAM 预算。

### Flash
1. 先 dry-run：`task nix:nixos-anywhere FLAKE="<flakeref>#<NODE>" HOST="<user>@<IP>" DISK=<device> [STAGED=true | PHASES=...] [AGE_KEY=...]`；核对命令、磁盘和 preflight 输出。优先用已安装的 nixos-anywhere；`nix run --refresh` 不锁版本。
2. 确认无误后执行：`DRY_RUN=false CONFIRM="<flakeref>#<NODE>"`；CONFIRM 必须等于 FLAKE，防止环境变量误触。host key 未知时 NA_ARGS 加 `--ssh-option StrictHostKeyChecking=accept-new`。
3. VPS 首次：`STAGED=true`（kexec → installer 检查/自动启用旧 swap → Enter 确认 → disko,install → 安装后检查，不自动 reboot）或 `PHASES=kexec,disko,install`（一次跑完不 reboot）。`NA_ARGS` 只放额外 flags（`--debug --option pure-eval false`、`--no-substitute-on-destination`）；不要在里面放 `--phases`。在 installer 检查 `/mnt/boot/initrd` 含 virtio（`lsinitrd ... | grep virtio`，或 `zstdcat ... | cpio -t`），再 reboot。
4. 默认 `PHASES=kexec,disko,install`（不自动 reboot）；要自动 reboot 用 `PHASES=kexec,disko,install,reboot`。`STAGED=true` 不自动 reboot；若直接 reboot，保留云控制台 OrcaTerm/VNC 兜底。

### First Boot
1. ssh-keygen -R <IP> 或 StrictHostKeyChecking=accept-new（刷机后 host key 变化；deploy-rs 非交互）。
2. 检查 hostname -s、id luck（1000/100）、`loginctl show-user luck | grep Linger=`（按 host 配置：dev/agt=yes；minimal/无 HM 如 rn2=no）、/run/secrets 和 /run/user/1000/secrets、systemctl is-active sshd fail2ban、lsinitrd /boot/initrd | grep virtio、nixos-option system.stateVersion。
3. 检查 /etc/fstab：grep -c NIXOS_SWAP /etc/fstab、findmnt --verify、swapon --show；检查 df -h /。
4. 从 host 配置读取要检查的关键服务（user/system 按 host 配置，不要写死）；如 agt 的 dagu、cloudcli、restic-backup.timer、derper/tailscale、mihomo、nezha。
5. 若未用 --chown 注入：chown -R luck:users /home/luck，再跑 home-manager/deploy。无 HM 的 minimal 节点（如 rn2）跳过 HM/deploy。

### Deploy And Recover
1. 确认目标 host 已启用 modules.infra.nix-tools.enable；否则目标机 nix.conf 没有 flakes/cache，remoteBuild=true 会失败。
2. 非交互 deploy：`nix run --impure .#deploy-rs -- --skip-checks .#<NODE> -- --impure`；交互式 `task nix:deploy` 用 gum choose，agent 不能操作。
3. remoteBuild 是 per-node（meta.nix）；失败临时改 false，deploy 后恢复。agt 的 nix-daemon MemoryMax=2000M，目标机 build 大 closure 可能 OOM。
4. HM 失败先查 /home/luck 权限；签名失败先确认 builder/target（VPS group 已有 require-sigs=false）；dbus-broker 用 deploy-rs `--boot` 或 `nixos-rebuild boot`，重启前检查 initrd；--skip-checks 不跳过 switchInhibitors。
5. SSH 失联用云控制台 OrcaTerm/VNC；实例可销毁则用控制台重装 Ubuntu 兜底。

### Wrap Up
1. 恢复 builder/target 临时 nix.conf、remoteBuild；删除临时 worktree。
2. 保留已刷入的 commit（squash 后合并），不要 reset；只清理未刷入的 WIP。
3. 按 Output 模板报告；遗留项写进 issue。

## Output

**交付：** 一份刷机报告，说明目标、阶段、closure、验收结果、deploy 结果和遗留项。

### Template

```markdown
## 刷机报告
- NODE / SSH_HOST / DISK：
- 目标机阶段：Ubuntu | installer | 已安装
- FLAKE / NA_ARGS / CONFIRM：
- closure size：<GB>；是否 system-only：
- 首启验收：hostname / uid / linger / sops / sshd / firewall / virtio / fstab / disk
- 角色服务：<从 host 配置读取>
- deploy-rs：confirmed | failed（原因）
- 临时变更是否恢复：
- 遗留项：
```
