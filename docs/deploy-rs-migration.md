# 从 Colmena 到 deploy-rs：一次彻底的解耦迁移记录

> 目标：用 deploy-rs 实现跨 profile（NixOS / nix-darwin / nix-on-droid）部署，同时把 inventory 从 Colmena 的部署字段中彻底解耦。

## 背景与动机

- Colmena 只覆盖 NixOS 节点，无法满足“跨 profile 统一下发/激活”的需求。
- 当前 inventory 与 Colmena 的 `targetHost/targetUser/targetPort/tags` 强耦合，导致：
  - 节点数据和部署工具绑死
  - 多 IP、业务字段和部署字段混杂
- 因此需要一条“纯数据 inventory + deploy-rs 适配器”的路径。

---

## 本次迁移的核心设计

### 1) inventory 变成纯数据（去 Colmena 字段）

旧：

- 依赖 `targetHost/targetUser/targetPort` 作为部署入口

新：

- 使用主机事实字段：
  - `primaryIp`：默认 SSH 目标
  - `ips`：同一节点的多 IP 列表
  - `ssh = { host, user, port }`：覆盖连接参数（可选）

收益：

- inventory 不再绑定任何部署工具
- 可被 deploy-rs、nixos-rebuild、其他工具复用

相关文件：

- `inventory/nixos-vps.nix`
- `lib/inventory.nix`

---

### 2) deploy-rs 适配器成为唯一部署入口

新增 `lib/inventory.nix` 的 `deployRsNode`：

- 把纯数据节点映射成 deploy-rs 的 `deploy.nodes.<name>` 结构
- 统一处理默认 SSH 用户、端口、远端构建策略

相关文件：

- `lib/inventory.nix`
- `outputs/x86_64-linux/src/nixos-vps.nix`
- `outputs/x86_64-linux/src/nixos-ws.nix`
- `outputs/x86_64-linux/src/nixos-homelab.nix`

---

### 3) 输出层切换到 deploy-rs

- 合并节点输出为 `deploy.nodes`
- 移除 `colmena` 输出与相关 meta
- 启用 deploy-rs 的 `deployChecks`

相关文件：

- `outputs/x86_64-linux/default.nix`
- `outputs/default.nix`

---

### 4) 完全移除 Colmena

- 删除 Colmena 输入、库与角色抽象
- 删除 Colmena 文档与任务
- 清理 Colmena 文本引用

相关文件：

- `flake.nix`
- `flake.lock`
- `Taskfile.nixos.yml`
- `lib/colmena-system.nix`（删除）
- `lib/mkColmenaRole.nix`（删除）
- `colmena.md` / `docs/colmena.md`（删除）

---

## deploy-rs 主要配置项（what + why）

以下为本仓库使用的 deploy-rs 核心字段（来自 `lib/inventory.nix` 的 `deployRsNode`）：

1. `hostname`

- what：远端 SSH 目标地址（IP/域名）
- why：将“连接地址”从 inventory 的 `primaryIp/ssh.host` 推导，避免再手写部署字段

2. `sshUser`

- what：SSH 用户名
- why：默认使用 `root`，但可被 `node.ssh.user` 覆盖，保持不同节点可差异化

3. `sshOpts`

- what：额外 SSH 参数（如端口）
- why：deploy-rs 没有单独的 `sshPort` 字段，必须通过 `-p` 传递

4. `remoteBuild`

- what：是否在远端构建（true 表示在目标机构建）
- why：与过去 Colmena 的 buildOnTarget 行为对齐，避免本地压力

5. `profiles.system.user`

- what：在远端激活 profile 的用户
- why：NixOS 系统 profile 必须以 root 激活

6. `profiles.system.path`

- what：具体激活路径（NixOS system closure）
- why：deploy-rs 通过 `deployLib.activate.nixos` 把系统 closure 变成可执行激活路径

7. `deployChecks`

- what：deploy-rs 自带的检查输出
- why：用于 CI/本地预检 deploy 输出结构是否正确

---

## 本次具体修改清单

1. **inventory 解耦**

- `inventory/nixos-vps.nix`：`targetHost` -> `primaryIp`
- `lib/inventory.nix`：新增 `primaryHostForNode` 与 `deployRsNode`
- `lib/singbox/client-config.nix`：用 `primaryHostForNode` 替代 `targetHost`

2. **deploy-rs 输出**

- `outputs/x86_64-linux/src/nixos-vps.nix`：生成 `deploy.nodes`
- `outputs/x86_64-linux/src/nixos-ws.nix`：改为直出 `deploy.nodes`
- `outputs/x86_64-linux/src/nixos-homelab.nix`：改为直出 `deploy.nodes`
- `outputs/x86_64-linux/default.nix`：汇总 `deploy.nodes`
- `outputs/default.nix`：暴露 `deploy` + 启用 `deployChecks`

3. **移除 Colmena**

- `flake.nix`：移除 Colmena 输入，新增 deploy-rs 输入
- `flake.lock`：清理 Colmena 相关依赖
- 删除 `lib/colmena-system.nix`、`lib/mkColmenaRole.nix`
- 移除 Taskfile 内 colmena 任务

4. **文档与注释清理**

- `vps.md`：更新为 deploy-rs 语义
- `modules/nixos/extra/singbox-client.nix`：更新注释
- `lib/singbox/config.nix`：更新注释
- `vars/default.nix`：移除 colmena 字样

---

## 结论

- inventory 已彻底解耦部署工具，成为纯数据层
- deploy-rs 成为唯一部署入口，支持跨 profile 扩展
- Colmena 已完全移除（代码、依赖、文档、任务）

后续如果要扩展到 nix-darwin / nix-on-droid，只需要给 deploy-rs 增加新的 profile 输出，不需要再动 inventory。

## 附：Taskfile 与模板

- deploy-rs 任务：`Taskfile.nixos.yml` / `Taskfile.darwin.yml` 已新增 `deploy-list` / `deploy` / `deploy-profile`。
- 跨 profile 模板：参考 `docs/deploy-rs-profiles.md`。
