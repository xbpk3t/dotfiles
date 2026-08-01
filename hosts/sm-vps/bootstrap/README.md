# sm-vps bootstrap（Phase 2–3）

在 `nixos-vps-dev` 的 Incus 容器 `linux-sm-lab` 上装多用户 Nix，激活 standalone HM（`homeConfigurations.sm-vps-lab`），并保证**用户向 sops** 可重复可用。

## 路径选择（R3 remoteBuild=false 思维）

| 步骤 | 在哪跑 | 说明 |
|------|--------|------|
| 装 Nix / 建用户 luck | **容器内** | Determinate 多用户；容器通常是 root |
| flake 源 | 宿主 rsync → 容器 `/home/luck/Desktop/dotfiles`，或 Incus disk 挂载 | 宿主工作树默认 `/home/luck/Desktop/dotfiles-sm`（Phase 未合入主 clone 时） |
| `home-manager switch` build | **容器内**（默认） | 容器自有 `/nix`；与宿主 store 因 idmap 不共享 |
| 可选：宿主 build + `nix copy` | 宿主 → 容器 | 未默认启用；容器需可达的 nix-daemon / 手工 copy |

## sops（Phase 3 正式路径）

与 `secrets/default.nix` 的 **linux** `age.keyFile` 对齐：

| 项 | 路径 / 行为 |
|----|-------------|
| age 私钥（容器 luck） | `/home/luck/.config/sops/age/keys.txt`（`~/.config/sops/age/keys.txt`） |
| 来源 | 宿主 `HOST_AGE_KEY`（默认 `/home/luck/.config/sops/age/keys.txt`）**incus file push**；**不入库** |
| 权限 | `0600`，属主 `luck:luck` |
| 解密产物 | `~/.config/sops-nix/secrets/<NAME>` → `/run/user/1000/secrets.d/N/...` |
| user systemd | `loginctl enable-linger luck` + `user@1000.service`；否则 activation 会跳过 sops |
| unit | `systemctl --user enable --now sops-nix.service`（oneshot，Result=success 即可） |

**不要**把 root/singbox 系统 secret 当 HM 验收目标；验收用已定义的 user secret（默认 `GITHUB_TOKEN`）。

`secrets/default.nix` 的 `isSystemConfig = config ? system` 在 standalone HM 下为 false，不写 owner/group（HM 模块语义）；NixOS 主航道仍走 system 分支——Phase 3 **不改**该判断。

## 用法（在宿主 nixos-vps-dev 上）

```bash
# Phase 2：Nix + 首次 HM switch
./hosts/sm-vps/bootstrap/phase2-hm.sh

# Phase 3：age key 正式放置 + linger/sops + 再 switch + 验证 secret 可读
./hosts/sm-vps/bootstrap/phase3-sops.sh

# 显式
CONTAINER=linux-sm-lab \
FLAKE_SRC=/home/luck/Desktop/dotfiles-sm \
HOST_AGE_KEY=/home/luck/.config/sops/age/keys.txt \
VERIFY_SECRET=GITHUB_TOKEN \
./hosts/sm-vps/bootstrap/phase3-sops.sh

# 只重装 key + 启 sops、不同步 flake / 不 switch
SYNC_FLAKE=0 RUN_HM_SWITCH=0 ./hosts/sm-vps/bootstrap/phase3-sops.sh
```

脚本幂等：key 可重复 push；linger / sops unit / switch 可重复跑。

## Milestone（容器内 luck）

```bash
test -r "$HOME/.config/sops/age/keys.txt"
test -r "$HOME/.config/sops-nix/secrets/GITHUB_TOKEN" && test -s "$HOME/.config/sops-nix/secrets/GITHUB_TOKEN"
# home-manager switch --flake …#sm-vps-lab -b hm.bak   # phase3 脚本内已跑
```

宿主主航道（不受本 phase 破坏）：

```bash
nix eval .#nixosConfigurations.nixos-vps-dev.config.networking.hostName
# → nixos-vps-dev
```
