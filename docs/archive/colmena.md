---
title: colmena
status: deprecated # active | deprecated | archived
owner: "@lucas"
last_reviewed: 2026-01-21
deprecated_since: 2026-01-21
adr: deploy-rs-migration.md # 只要是 status != active 的文档 必须有 reason + replacement 或 adr
replacement: deploy-rs.md
reason: 用 deploy-rs 替代 colmena
---

# colmena

## 当前实现概览

- 入口：`outputs/default.nix` 暴露 `colmena`，`meta` 默认用 `x86_64-linux` 的 `nixpkgs` 与 `genSpecialArgs`。
- 角色文件：`outputs/x86_64-linux/src/*.nix` 只写元数据（模块列表、目标主机列表、标签、特参函数）。
- 抽象封装：`lib/mkColmenaRole.nix` 统一将一个角色的 `targets` 扇出为多节点，生成两类输出：
  - `nixosConfigurations.<node>`
  - `colmena.<node>`（包含 `deployment.targetHost/targetUser/targetPort/tags`）

## 使用方式

- 查看节点：`nix eval .#colmena --apply builtins.attrNames`
- 部署三台 VPS：`colmena apply --on '@batch-vps' --impure --show-trace`
- 单节点部署：`colmena apply --on nixos-vps-103-85-224-63 --impure --show-trace`
- 新增/调整主机：在对应 role 文件的 `targets` 增删一行 `{ host = "..."; user = "..."; tags = [...] ; port = null; }`，标签可自定义以便 `--on '@tag'` 选取。

## 为什么不直接抄 nix-config 的“一主机一文件”写法

- 需求差异：你要“同一角色扇出多主机”，而 nix-config 以“一文件一节点”为主；照抄会导致重复代码增多，扇出能力缺失。
- 可读性与重复度：通过 `mkColmenaRole` 抽象，角色公共模块/特参写一次，targets 列表即可多机；避免为每台机器复制整段模块清单。
- 兼容性：保持顶层输出结构与 Colmena 预期一致（`meta + 节点`），CLI 行为与官方一致；仍可用标签批量部署。

## colmenaTargets 和 hosts 一对多关系 [2026-01-05]

:::danger

一开始尝试直接参考 colmena 官方example，做出修改

但是尝试修改后发现，写法很不简洁。

所以最终选择了在 [ryan4yin/nix-config](https://github.com/ryan4yin/nix-config) 里colmena写法的基础上，修改为 role 和 hosts 一对多的写法。

其实这里涉及到两个

- outputs 是用来干啥的？
- outpust 和 hosts 之间的关系？

**_因为我需要 “role 扇出多 host”，所以修改了 nix-config 的“一主机一文件”的colmena 写法_**

:::

### 目前colmena用法 vs colmena官方写法

背景：当前 flake 中的 Colmena 输出使用 `colmenaTargets` + `mkNodes` 扇出 DSL；计划迁移到官方推荐的一节点一主机写法（`colmena.lib.makeHive` 或手写节点 attrset）。下表对两种写法的核心取舍做并列说明。

#### 当前写法

- `lib/colmena-system.nix` 提供公共 helper，把与 `nixosConfigurations` 相同的模块 / Home‑Manager 输出给 Colmena。
- `outputs/x86_64-linux/src/nixos-vps.nix` 与 `nixos-ws.nix` 都会根据 `vars/networking.colmenaTargets` 自动生成节点，避免重复维护。
- `vars/networking.nix` 中的 `colmenaTargets.<name>` 字段格式：
  ```nix
  colmenaTargets = {
    nixos-vps = {
      config = "nixos-vps";        # 对应 hosts/<config>/
      targetHost = "10.254.0.2";   # SSH 目标（容器）
      targetUser = "root";
      tags = ["vps" "container" "lab"];
      targetPort = null;           # 可选
      extraModules = ["modules/roles/..."?];
      extraConfig = { boot.isContainer = true; }; # 可选 inline module
    };
    nixos-hk = {
      config = "nixos-vps";
      targetHost = "103.85.224.63";
      targetUser = "root";
      tags = ["vps" "hk" "prod"];
      extraConfig.networking.hostName = "nixos-hk";
    };
    nixos-ws = {
      config = "nixos-ws";
      targetHost = "192.168.234.194";
      targetUser = "luck";
      tags = ["workstation"];
    };
  };
  ```
- `extraConfig` 会作为额外 module 注入。上例里容器节点自动 `boot.isContainer = true`，而香港 VPS 会覆盖 `networking.hostName`。

---

- 容器（本地）dry-run：`colmena apply --on nixos-vps --impure --dry-run`
- 香港 VPS 部署：`colmena apply --on nixos-hk --impure --show-trace`
- 测试标签：`colmena apply --on '@vps' --impure`

Colmena 的 `meta.nixpkgs` / `meta.specialArgs` 会自动继承 flake 的 `genSpecialArgs`，所以所有节点共享同一套 overlay 与 pkgs。

#### 为什么选这些对比项

- **可读性/上手成本**：日常维护时，阅读链路越短越好。
- **调试路径**：部署异常时，能否直接在 hive 里定位 `deployment.*` 与 imports。
- **与社区/文档一致度**：影响新人学习成本与搜到解决方案的概率。
- **多实例扇出能力**：是否需要一套 profile 扇出多台；这是 DSL 最初存在的理由。
- **公共配置复用**：能否集中写 meta/defaults、共享 nixpkgs/specialArgs。
- **失效风险（当前问题）**：现状 `targetHosts` 多项时无法 push，这是必须解决的痛点。
- **演进灵活性**：未来再添节点/拆文件的容易程度。

#### 对比表

| 对比项                            | 现有写法（colmenaTargets+mkNodes） | 官方写法（makeHive / 手写节点） | 判断理由                                                                                              |
| --------------------------------- | ---------------------------------- | ------------------------------- | ----------------------------------------------------------------------------------------------------- |
| 可读性/上手成本                   | ❌                                 | ✅                              | 官方形式与文档一致，一眼能看到 `deployment.*`；现有写法需理解 `colmenaTargets→mkNodes` 才能追到节点。 |
| 调试路径                          | ❌                                 | ✅                              | 官方写法节点即结果，`colmena eval` 与文件定义一致；DSL 需 mentally 展开，出错时定位更慢。             |
| 与社区/文档一致度                 | ❌                                 | ✅                              | 官方示例、博客几乎都用 makeHive/手写；DSL 属自定义，外部资料少。                                      |
| 多实例扇出能力                    | ✅                                 | ❌                              | DSL 可用一个 profile 扇出多 host（但当前实现有 bug）；官方需逐节点手写或轻量循环。                    |
| 公共配置复用                      | ⬜                                 | ✅                              | makeHive 支持 `meta`/`defaults` 原生承载；DSL 也能复用但需自定义 glue。                               |
| 当前可用性（多 host push）        | ❌                                 | ✅                              | 现状 `targetHosts` >1 时 push 失败；官方一节点一 host 天然规避。                                      |
| 演进灵活性（拆文件、分 prod/dev） | ⬜                                 | ✅                              | 官方可轻松拆 `hive.nix`/`inventory.nix` 并保持明文；DSL 拆分后仍需保持生成链完整。                    |

符号说明：✅ 优势，❌ 劣势，⬜ 中性/取决于用法。

#### 结论

- 现阶段节点数量不大，且已遇到多 host 失效问题，推荐切换到官方写法（makeHive 或等价手写节点）。
- 若未来再次需要批量扇出，可以在官方写法上用小型循环生成节点，但保持“一节点一 host、部署字段明文”，避免回到复杂 DSL。

:::caution

> 主流/官方推荐的做法就是用独立的 hive.nix 来定义 meta/defaults/节点，然后在 flake 输出里暴露 colmena 供 CLI 使用——而不是塞在 outputs/x86_64-linux/default.nix 里。

但是只要是这种写法，就不可能做到很简洁，因为所有 nodes的metadata都需要放到这个 hive.nix 里。并且还有大量适配代码（也就是 outputs里的那堆）。

从代码简洁来说，不如直接放到 outputs里，直接复用。

:::

### ryan4yin 的写法

- flake 的 outputs 里用 haumea 把 `outputs/<system>/src/*.nix` 聚合，每个文件产出 `nixosConfigurations`/`colmenaProfiles`；真正的主机配置在 `hosts/<name>/` 目录。
- `hosts/<name>/default.nix` 里通过 `mylib.scanPaths ./.` 把同目录下的模块一次性拉全，这意味着**把额外的覆盖文件放进同一目录会直接影响原主机**。

但是问题在于

他这个写法，_每个host，都会有唯一的 outputs + hosts_

每个outputs里会写colmena各host的metadata

然后通过lib把这些metadata抽取成colmena需要的 makeHive 里的格式。以此，就做到了不需要手动去写 makeHive 里的 metadata，同样可以使用colmena。很优雅的做法。

但是问题在于我的 `outputs+hosts` 更类似role，这二者之间是一对一关系。而最终，这个role跟 最终部署的hosts，是一对多关系。也就是每个role都可以在多个 host IP之间复用。

### 对 chat 过程的分组回顾（问↔答）

- Q：nix-config 的 colmena 写法能否直接用？
  A：可行但不必要；它一机一文件，与你的“角色扇出”需求不符，建议按自身需求重构。
- Q：如何把现有 colmenaTargets/mkNodes DSL 改成简洁写法？
  A：移除 DSL，节点文件直接导出 `colmena.<name> = mylib.colmenaSystem ...`；后续演进为 `mkColmenaRole` 抽象。
- Q：如何一次部署多台 VPS？
  A：给多节点统一标签（如 `batch-vps`），`colmena apply --on '@batch-vps' --impure --show-trace`。
- Q：为何仍有 specialArgs.pkgs warning？
  A：因手动塞了 `pkgs` 进 specialArgs，可接受或在公共模块引入 `nixosModules.readOnlyPkgs` 后设 `nixpkgs.pkgs = pkgs` 以消除。
- Q：能否把重复代码抽到 lib？
  A：已新增 `lib/mkColmenaRole.nix`，角色文件只保留元数据与 targets。

### 结论

- 现方案满足“角色扇出多主机、标签批量部署、最少重复”的需求，保持与 Colmena 官方输出结构兼容。
- 后续扩容只需在各角色 `targets` 列表添加项，无需再写模板函数或额外 DSL。
- 如果要消除 specialArgs.pkgs 警告，可在公共 NixOS 基础模块引入 `nixosModules.readOnlyPkgs` 并设置 `nixpkgs.pkgs = pkgs`；否则可忽略。
