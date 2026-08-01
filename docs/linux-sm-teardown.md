# linux-sm 删除清单（Phase 1 初稿）

踢掉本轨时按下列 path/input/merge 键清理。终稿在 Phase 6 收束。

## flake inputs

- `flake.nix` → `inputs.system-manager`（及 `flake.lock` 对应节点）

## lib

- `lib/home-standalone.nix`
- `lib/system-manager.nix`
- `lib/default.nix` 中的 `homeStandalone` / `systemManager` export
- `lib/inventory/data.nix` → 组 `linux-sm`（节点 `linux-sm-lab`）
- `lib/inventory/utils.nix` → `"linux-sm"` 分组入口
- （后续 phase 若新增）`lib/inventory` 内 `deploySmHmNode` 等，**勿**误删 `deployRsNode`

## modules

- `modules/system/**`（整树；与 `modules/nixos/**` 无关）

## outputs

- `outputs/x86_64-linux/src/linux-sm.nix`
- `outputs/default.nix`：
  - `mergeRoleOutputList` 的 `homeConfigurations` / `systemConfigs`
  - `mergedHomeConfigurations` / `mergedSystemConfigs`
  - `flake.homeConfigurations` / `flake.systemConfigs`

## hosts / bootstrap（后续 phase 占位）

- `hosts/linux-sm/**`（若已创建）
- bootstrap 脚本 / Taskfile `nix:linux-sm:*`（Phase 2+ / 6）

## docs

- `docs/linux-sm-phases.md`
- `docs/linux-sm-teardown.md`（本文件）
- 其它 README 中 linux-sm 段落

## 验证踢干净

```bash
# 下列 attr 应不存在
nix eval .#homeConfigurations.linux-sm-lab --apply 'x: true'  # 期望 attribute missing
nix eval .#systemConfigs.linux-sm-lab --apply 'x: true'       # 期望 attribute missing
# 主航道仍在
nix eval .#nixosConfigurations.nixos-vps-dev.config.networking.hostName
```

## 注意

- 不要改/删 `modules/nixos/**` 以“清理”本轨。
- 不要用浅 `//` 改 `deployRsNode` 或 vps `networking` 合并逻辑。
- 容器 `linux-sm-lab` 本体在 `nixos-vps-dev` Incus 上，代码踢掉后容器可另 `incus delete`。
