# sm-vps Ansible bootstrap

非 NixOS 真机的 day-0 引导，替代原 `hosts/sm-vps/bootstrap/` 下的 shell 脚本。
目标：已有 SSH 的裸 Debian/Ubuntu（或 RHEL 系）→ luck 用户 + Determinate Nix
+ standalone HM + system-manager + tailscale + sops + sshd 硬化。

## 为什么用 Ansible（vs shell）

原 phase8-real.sh 是 bash 顺序脚本。Ansible 带来：
- **分 play 表达「自锁保护」**：P0 建 luck → P1 验证 luck+key → P4 才锁 sshd，
  比 `set -e` + 顺序更显式，P1 连不上整场中止
- **幂等模块**：user/group/copy/package/authorized_key/synchronize 自带状态检查，
  HM/sm switch 用 `creates:`/`changed_when` 尽量幂等
- **inventory 承载多机**：加一行 inventory 即可扩展到 N 台

## 用法

```bash
# 1. 装依赖 collection
ansible-galaxy collection install -r hosts/sm-vps/ansible/requirements.yml

# 2. 首次 bootstrap（需 root 密码）
ansible-playbook -i hosts/sm-vps/ansible/inventory/sm_vps.ini \
  hosts/sm-vps/ansible/bootstrap.yml --ask-pass

#   或 root 密码走环境变量（CI/非交互）：
#   ANSIBLE_PASSWORD='<root密码>' ansible-playbook ... bootstrap.yml

# 3. 后续重跑（luck+key，无需密码）
ansible-playbook -i hosts/sm-vps/ansible/inventory/sm_vps.ini \
  hosts/sm-vps/ansible/bootstrap.yml
```

## Play 结构

| Play | 连接身份 | 内容 |
|------|----------|------|
| P0 | root+密码 | preflight（os_family 断言）+ 建 luck 用户/sudoers/authorized_key |
| P1 | luck+key | 验证登录 + sudo NOPASSWD（连接成功即自锁保护检查） |
| P2 | root+密码 | Determinate Nix + rsync flake + age key + linger |
| P3 | luck+key | HM switch + system-manager switch + tailscale + sops 验证 |
| P4 | root+密码 | sshd 硬化 + 回归验证 luck 登录 |

## 关键设计点

- **root 密码**：只 P0/P2/P4 用（`ansible_user=root`），来自 `--ask-pass` 或 `ANSIBLE_PASSWORD` 环境变量，不落盘。仍需 sshpass（和 bash 版一样）。
- **Determinate Nix**：无官方 Ansible role，用 `get_url` + `command` + `creates:`（已装则跳过，幂等）。
- **HM/sm switch**：无 Ansible 模块，用 `command` + `changed_when: false`（每次重跑，标记不变更）。用完整 nix 路径避 sudo PATH 重置问题。
- **tailscale**：官方 repo + `package` + `tailscale up`（`creates: /var/lib/tailscale/tailscaled.state` 幂等）。
- **sshd 硬化**：`copy` + `validate: sshd -t`（等价 bash 的 `sshd -t`）+ `systemd` reload。

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
| step 4（rsync flake） | P2 2d-2e |
| step 5-6（age key + linger） | P2 2f-2k |
| step 7-8（HM/sm switch） | P3 3a-3b |
| step 9（tailscale） | P3 3c-3e |
| step 10（sops 验证） | P3 3f |
| step 11（锁 sshd） | P4 |
