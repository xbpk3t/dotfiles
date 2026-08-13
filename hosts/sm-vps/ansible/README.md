# sm-vps Ansible bootstrap

非 NixOS 真机的 day-0 引导，替代原 `hosts/sm-vps/bootstrap/` 下的 shell 脚本。
目标：已有 SSH 的裸 Debian/Ubuntu（或 RHEL 系）→ luck 用户 + Determinate Nix
+ 基础配置（sshd/sops age key）+ 可选的 tailscale。HM/system-manager 收敛走 deploy-rs。

## 为什么用 Ansible（vs shell）

原 phase8-real.sh 是 bash 顺序脚本。Ansible 带来：
- **分 play 表达「自锁保护」**：P0 建 luck → P1 验证 luck+key → P4 才锁 sshd，
  比 `set -e` + 顺序更显式，P1 连不上整场中止
- **幂等模块**：user/group/copy/package/authorized_key 自带状态检查
- **inventory 承载多机**：加一行 inventory 即可扩展到 N 台

## 架构分工（重要）

**bootstrap 只做「系统基础」**（用户、Nix、配置、可选 tailscale）：
```
bootstrap（Ansible）→ 装 Nix + 建用户 + sshd/sops 配置
     ↓
deploy-rs → HM/system-manager 收敛（remote_build，不需目标机 flake 源码）
     ↓
task nix:deploy:smoke → 验证（etc/unit/secret/tailnet/SSH）
```

所以 bootstrap **不** rsync flake、**不**做 HM/sm switch——那些是 deploy-rs 的职责
（S3 已打通）。目标机上也不保留 dotfiles 源码树。

## 用法

```bash
# 1. 装依赖 collection
ansible-galaxy collection install -r hosts/sm-vps/ansible/requirements.yml

# 2. 首次 bootstrap（需 root 密码）
ansible-playbook -i hosts/sm-vps/ansible/inventory/sm_vps.ini \
  hosts/sm-vps/ansible/bootstrap.yml --ask-pass

#   或 root 密码走环境变量（CI/非交互）：
#   ANSIBLE_PASSWORD='<root密码>' ansible-playbook ... bootstrap.yml

# 3. bootstrap 完成后：
#    - HM/sm 激活：task nix:deploy:sm NODE=<node>
#    - 验证：task nix:deploy:smoke NODE=<node>
#    ⚠️ 首跑后 root 密码登录被锁，P0/P2/P4（root 身份）无法再连。
#      重跑基础配置：--tags bootstrap-p3（luck 身份，只跑 P3）
```

## Play 结构

| Play | 连接身份 | 内容 |
|------|----------|------|
| P0 | root+密码 | preflight（os_family 断言）+ 建 luck 用户/sudoers/authorized_key |
| P1 | luck+key | 验证登录 + sudo NOPASSWD（连接成功即自锁保护检查） |
| P2 | root+密码 | Determinate Nix + age key（用户/系统）+ linger + bus 等待 |
| P3 | luck+key | tailscale repo/package/up + 提示（HM/sm/sops 走 deploy-rs） |
| P4 | root+密码 | sshd 硬化 + 回归验证 luck 登录 |

## 关键设计点

- **root 密码**：只 P0/P2/P4 用（`ansible_user=root`），来自 `--ask-pass` 或 `ANSIBLE_PASSWORD` 环境变量，不落盘。仍需 sshpass（和 bash 版一样）。
- **Determinate Nix**：无官方 Ansible role，用 `get_url` + `command` + `creates:`（已装则跳过，幂等）。
- **HM/sm switch**：不在 bootstrap——走 deploy-rs（S3）。
- **tailscale**：官方 repo + `package` + `tailscale up`（`sm_ts_authkey_src` 提供 authkey 才 up）。
- **sshd 硬化**：`copy` + `validate: sshd -t` + `systemd` reload。
- **tags**：`bootstrap-p0..p4` 分 play；`--tags bootstrap-p3` 只跑 luck 身份的重跑路径。

## distro 适配

| 差异 | Debian/Ubuntu | RHEL/CentOS/Fedora | Ansible 处理 |
|------|---------------|--------------------|--------------|
| 包管理器 | apt | dnf/yum | `package` 模块通吃 |
| admin 组 | `sudo` | `wheel` | `group_vars` 里 `sm_groups`（默认 sudo，RHEL 改 wheel） |
| sshd 服务名 | `ssh` | `sshd` | P4 按 `ansible_os_family` 选 |
| 包名差异 | xz-utils | xz | P2 用 `package`，RHEL 需在 group_vars 调整 |

注意：`ansible_os_family` 对 Ubuntu 是 `Debian`，对 Fedora 是 `RedHat`。
sm-vps 硬前提是 **systemd 发行版**（P0 断言），Alpine（OpenRC）不支持。

## 与旧 shell 脚本的映射

| 旧脚本 | Ansible 对应 |
|--------|-------------|
| phase8-real.sh step 1（建用户） | P0 1a-1d |
| step 2（验证登录） | P1 |
| step 3（Nix 安装） | P2 2a-2c |
| step 5-6（age key + linger + bus） | P2 2f-2m |
| step 9（tailscale） | P3 3c-3e |
| step 11（锁 sshd） | P4 |
| step 4（rsync flake）/7/8（HM-sm switch）/10（sops） | → deploy-rs（S3/S4） |
