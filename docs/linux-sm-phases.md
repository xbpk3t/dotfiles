# linux-sm 分 phase 计划

冻结决策：A 主仓平行轨 · 1B HM+sm · 2A deploy-rs 多 profile · P1 root · U3 · R3 默认 remoteBuild=false · T2 · S2 · W1 床先于业务。

试验床：`nixos-vps-dev`（192.129.183.26）上 Incus 系统容器 `linux-sm-lab`（Debian 12，PID1=systemd）。

硬约束：

- 不 import `modules/nixos/**` 进 sm
- 不改坏现有 `deployRsNode` / nixos-vps hostName
- 踢掉清单与代码同生
- 每 phase：实现 → 在床上验证 → 主 agent 验收 → commit → 下一 phase

---

## Phase 0 — Incus 床（已完成）

**范围：** 仅 `nixos-vps-dev` 最小 Incus（I1+P-b）。

**Milestone：** daemon active、`incus-admin`、`init --minimal`、Debian 容器 systemd running。

**状态：** 已部署验收；本文件落地时一并 commit。

---

## Phase 1 — 平行轨脚手架（只 eval，不要求靶机 switch）

**范围：**

- `inputs.system-manager`
- `lib/home-standalone.nix`（或 `lib/home.nix`）：`homeManagerConfiguration`
- `lib/system-manager.nix`：`makeSystemConfig` 包装
- `lib/inventory` 新组 `linux-sm` + 节点 `linux-sm-lab`（指向床元数据）
- `outputs/x86_64-linux/src/linux-sm.nix` 平行 role
- `outputs/default.nix`：`mergeRoleOutputList` + `flake` 增加 `homeConfigurations` / `systemConfigs`
- 最小 module 列表：HM 仅 `home/core`（可先无 sops）；sm 仅 platform + 空/ nix 设置占位
- `docs/linux-sm-teardown.md` 删除清单初稿
- **禁止** 改 `modules/nixos`、禁止动现有 nixos deploy 默认路径

**Milestone：**

```bash
nix eval .#homeConfigurations.linux-sm-lab.config.home.username
nix eval .#systemConfigs.linux-sm-lab  # 或等价 attr 存在且能求值
# 现有主航道不回归：
nix eval .#nixosConfigurations.nixos-vps-dev.config.networking.hostName  # == nixos-vps-dev
```

**不在本 phase：** 往容器里 install nix / switch / sops key / deploy-rs profile。

---

## Phase 2 — 容器 bootstrap + standalone HM switch

**范围：**

- 床内：Determinate/多用户 Nix（脚本可放 `hosts/linux-sm/bootstrap/` 或 task）
- 用户 `luck`（U3 POC）
- `home-manager switch --flake ...#linux-sm-lab`（或 deploy 前的本机/跳板 activate）
- `backupFileExtension = "hm.bak"` 仅 linux-sm
- 复用 `home/core` only

**Milestone：**

- 容器内 `nix --version`
- switch 成功；登录 shell 可见 HM 管理的工具/路径（如 `home-manager generations` 或 zsh 来自 profile）
- 主航道 host-eval 未因 home 改动失败（本 phase 尽量不改 home 模块本体）

---

## Phase 3 — 用户 sops（S2）

**范围：**

- standalone HM 挂 `sops-nix.homeManagerModules` + `secrets/default.nix`（用户向）
- bootstrap：age key 落到约定路径（容器内）
- **不**接 root/singbox 系统 secret

**Milestone：**

- 至少 1 个 user secret path 可读（如已有 API 类或测试用 key）
- HM 再次 switch 成功；无改坏 `isSystemConfig` 对 NixOS 的行为

---

## Phase 4 — system-manager T2

**范围：**

- `modules/system/*` 新树（与 nixos 分树）
- T2：Nix 相关设置/最小 systemPackages **+ 一个服务**（优先 **sshd drop-in 或 tailscale 二选一**；容器内 tailscale 可能更烦，**默认 sshd 加固 drop-in 或一个简单 systemd oneshot/timer 证明收敛**——若 sshd 不合适则 `environment.etc` 托管一个 flag 文件 + 自定义 unit 亦可，但必须是 sm 声明态）
- 在 `linux-sm-lab` 上 `system-manager switch`

**Milestone：**

- switch 成功；声明的 etc 或 unit 存在且再 switch 幂等
- 不破坏容器网络到宿主的基本连通

---

## Phase 5 — deploy-rs 多 profile

**范围：**

- **新建** `deploySmHmNode`（勿改坏 `deployRsNode`）
- profiles：`system`（sm custom activate）+ `home`（`activate.home-manager`）
- `profilesOrder = [ "system" "home" ]`
- `remoteBuild` 默认 false（R3），inventory 可覆写
- 从构建机（vps-dev 或本地 linux）`deploy` 到 lab（SSH 进容器或经宿主跳转——实现时选稳定路径并写进文档）

**Milestone：**

- 一次 `deploy`（或明确两条 profile 命令）更新 system+home
- 改一个无关紧要的声明后再 deploy，能收敛

---

## Phase 6 — 收尾

**范围：**

- 删除清单终稿、简短 README（如何加第二台、如何踢掉）
- Taskfile 入口（可选 `nix:linux-sm:*`）
- 确认主航道 `task nix:deploy:vps` / hostName / incus 仍好
- 第二节点仅文档或 inventory 占位（不强制真机）

**Milestone：** 文档齐全；主航道 smoke；linux-sm 双轨仍可 deploy。

---

## Sub-agent 约定

- 每 phase 一个 agent；结束必须回报：改了哪些路径、验证命令与输出摘要、是否达标、阻塞项
- 不重开架构争论；不引入 Ansible；不 import modules/nixos
- 失败时修到 milestone 绿，或明确无法完成原因
- **Commit 仅主 agent 在验收后执行**
