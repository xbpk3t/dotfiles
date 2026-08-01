# sm-vps bootstrap（Phase 2+）

在 `nixos-vps-dev` 的 Incus 容器 `linux-sm-lab` 上装多用户 Nix，并激活 standalone HM（`homeConfigurations.sm-vps-lab`）。

## 路径选择（R3 remoteBuild=false 思维）

| 步骤 | 在哪跑 | 说明 |
|------|--------|------|
| 装 Nix / 建用户 luck | **容器内** | Determinate 多用户；容器通常是 root |
| flake 源 | 宿主 rsync → 容器 `/home/luck/Desktop/dotfiles`，或 Incus disk 挂载 | 宿主工作树默认 `/home/luck/Desktop/dotfiles-sm`（Phase 未合入主 clone 时） |
| `home-manager switch` build | **容器内**（默认） | 容器自有 `/nix`；与宿主 store 因 idmap 不共享 |
| 可选：宿主 build + `nix copy` | 宿主 → 容器 | 未默认启用；容器需可达的 nix-daemon / 手工 copy |

sops：switch 激活会跑 sops-install-secrets。Phase 2 用宿主已有 age key 拷入容器 `~/.config/sops/age/keys.txt`（POC）；完整 S2 属 Phase 3。

注意：容器默认无 user lingering 时，activation 里 `reloadSystemd` / `sops-nix` 会提示 *User systemd daemon not running* 并跳过。脚本会 `loginctl enable-linger luck` 并 `systemctl start user@1000` 后再 `systemctl --user start sops-nix`。

## 用法（在宿主 nixos-vps-dev 上）

```bash
# 从仓库根或任意处；脚本自定位
./hosts/sm-vps/bootstrap/phase2-hm.sh

# 或显式
CONTAINER=linux-sm-lab \
FLAKE_SRC=/home/luck/Desktop/dotfiles-sm \
./hosts/sm-vps/bootstrap/phase2-hm.sh
```

脚本幂等：已装 Nix / 已有 luck / 已 switch 可重复跑。
