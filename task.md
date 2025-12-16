# NU Migration Plan (haumea ➜ nixos-unified)

> 指南：除非为 haumea → NU 适配所需，不改动 nix 文件内容，只做搬运/接线。完成步骤后打勾。

- [ ] 阶段 0：基线
  - [ ] 记录当前 haumea 分支可用（已在新分支上）。
  - [ ] 保留现有 flake.lock 作为对照。

- [x] 阶段 1：目录与骨架
  - [x] 创建 NU 约定目录：`configurations/{nixos,darwin,home}`、`modules/{nixos,darwin,home,flake}`、`overlays/`、`packages/`（仅缺的再建）。
  - [x] 在根 flake 添加 NU 入口（保留旧 outputs）：`inputs.nixos-unified.lib.mkFlake { inherit inputs; root = ./.; }`。

- [x] 阶段 2：specialArgs & flake-parts 接线
  - [x] 将 `outputs/default.nix` 中的 `genSpecialArgs` 等注入逻辑迁移为 flake-parts/NU `_module.args`（不改业务逻辑）。
  - [x] overlay 与 `config.allowUnfree/allowBroken` 挪至 `modules/flake` 级别。

- [ ] 阶段 3：模块/主机搬运
  - [x] 将各平台主机文件移入 `configurations/{nixos,darwin}`，home 配置移入 `configurations/home`。
  - [x] 共享模块移入 `modules/{nixos,darwin,home}`；flake 级模块移入 `modules/flake`。
  - [ ] 若需自定义 attr 命名，用 NU autowiring 约定或最小辅助代码，避免改动模块内容。

- [ ] 阶段 4：可选自动导入扩展
  - [ ] 仅当需要 haumea loader/transformer 灵活度时，添加自定义 flake-parts 模块或局部 import；否则依赖 NU autowiring。

- [ ] 阶段 5：测试验证
  - [ ] 运行 `nix flake check`（或等效）确保新结构通过。
  - [ ] NixOS 主机 dry-run：`nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run`。
  - [ ] macOS（Determinate Nix 环境）dry-run：若未安装 `darwin-rebuild`，用 `nix build .#darwinConfigurations.<host>.system --dry-run` 验证；实际切换可用 `sudo nix run nix-darwin -- switch --flake .#<host>` 或 NU 的 `nix run .#activate`。
  - [ ] Home 配置 dry-run：`nix build .#homeConfigurations."<user>@<system>".activationPackage --dry-run`。
  - [ ] DevShell/formatter 验证：`nix develop`、`nix fmt`。

- [ ] 阶段 6：并行对比
  - [ ] 与旧 outputs 并行评估，必要时 `nix store diff-closures` 比对关键主机。
  - [ ] 确认 colmena 节点列表与旧逻辑一致。

- [ ] 阶段 7：切换与清理
  - [ ] 去除 haumea/namaka 依赖并移除 legacy outputs（或迁到 `legacy-outputs/`）。
  - [ ] 更新 README/cheatsheet，记录 `nix run .#activate / #update` 用法与目录约定。

- [ ] 阶段 8：交付
  - [ ] 在 PR/提交中附迁移说明、dry-run/flake check 结果与差异结论。
  - [ ] 设定 flake 更新节奏（如月更），关注 NU changelog。
