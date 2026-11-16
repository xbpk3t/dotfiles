# lorenzorapetti 两仓库吸收分析（nix / dotfiles）

扫描日期：2026-11-16。同一作者的两个 repo 按一组分析；候选编号用 A/B 前缀，本报告只有 A 前缀候选，B 无值得吸收项。

## 0. 锚定

### A. lorenzorapetti/nix

- 目标：lorenzorapetti/nix @ 670399b982f3ab8c278cb6805a7f5d9e7bffa138（2026-11-15），扫描日期 2026-11-16（非降级模式）。
- pin：`flake.lock` 已跟踪。root input `nixpkgs` 实际映射到 lock 节点 `nixpkgs_4` = NixOS/nixpkgs `nixos-unstable`，rev `d4f25a3e5620`（lastModified 2026-11-11）。本地同 channel rev `6510408d147d`（2026-10-10），A 比本地新约 1 个月；两边都是 tracked lock + nixos-unstable，pin 策略一致。注意 lock 里同名的 `nixpkgs` 节点是 tarball（被 bun2nix 引用），不是顶层 pin。
- 规模：107 个 .nix / 6723 行（>5000 行，按 map 后抽样）；精读 30 个核心文件 + 约 15 个小模块片段，其余按目录结构推断。
- 架构摘要：单 flake（flake-parts + import-tree + den）。`modules/` 下每个 .nix 是自包含的 dendritic 模块（`_` 前缀除外，供手动 import）；den entities 声明 host/user，feature aspects 用 `includes` 组合 nixos + homeManager；homelab 服务（traefik / technitium / glance / atticd / actual）各一个 aspect，自带端口、Traefik 路由、secret、systemd 配置；networking 是独立 aspect 组；`dotfiles/` 是仓库内的可变配置（claude-code、herdr-app、vicinae、ccstatusline），由 HM 链接到 $HOME。关键分支：`modules/{hosts,homelab,networking,desktop,development,hardware,shell,ai,secrets,users,_lib}`、`docs/new-host.md`；无 `tests/`、无 `.github/`。

### B. lorenzorapetti/dotfiles

- 目标：lorenzorapetti/dotfiles @ 8e5752017dfc24ab533336c53cc34f7706d155be（2026-06-30），扫描日期 2026-11-16（非降级模式）。
- pin：无 flake、无 flake.lock；Arch/CachyOS 包列表 `install/packages/*.packages` 不锁版本，`common/.config/mise/config.toml` 只锁 node=24 / bun=1 / deno=2 大版本。HEAD 比 A 早约 4.5 个月。
- 规模：255 个文件 / 16 个 .lua / 0 个 .nix；精读 10 个关键文件（CLAUDE.md、install.sh、.stow-local-ignore、Hyprland Lua 入口与环境、.luarc.json/stylua、zellij-sesh、fish/mise/opencode 配置、wiki-troubleshoot skill），其余按目录结构推断。
- 架构摘要：Arch/CachyOS + Hyprland 的 stow dotfiles。`common/`（跨平台）、`linux/`（Hyprland/Wayland）、`macos/`（aerospace/ghostty）三棵树镜像 `$HOME`；`stow --no-folding` 部署；`install/` 负责 pacman/paru 包列表、SDDM 主题、蓝牙 autosuspend 修复、nvim 外链；Hyprland 配置是 Lua 模块 + gitignored 的 `monitors.lua`（hyprmoncfg 生成）。
- 职责边界：A 已把系统 + HM + 可变 dotfiles 收敛到单个 flake；B 是 Nix 化之前的 Arch 时代 dotfiles，仓库内无任何 Nix/HM 集成（0 个 .nix 文件，grep 只命中普通工具配置里的 "nix" 字样），其职责已被 A 的 `dotfiles/` + HM 模块取代。

### 本地已有能力（对比基准）

- flake-parts 顶层 + `outputs/` 按 system 聚合：`flake.nix:145-207`、`outputs/default.nix:96-358`。
- 三平台（x86_64-linux / aarch64-linux / aarch64-darwin）+ deploy-rs + system-manager 平行轨。
- inventory 单一数据源 + nix-unit 一致性断言：`lib/inventory/data.nix`、`tests/nix-unit/host-metadata.nix`。
- 质量闸门：deployChecks + `host-eval-*` / `hm-eval-*` + scan-paths + nix-unit：`outputs/default.nix:202-322`。
- CI：flake-check / pre-commit / update-flake-lock：`.github/workflows/*.yml`。
- secrets：sops-nix + age，manifests 与 secrets 两条 creation_rules：`.sops.yaml:1-25`、`secrets/default.nix`。
- 工程化：Taskfile 多层 include、pre-commit（跨语言）、treefmt(nixfmt)、APM 指令、nixos-anywhere 脚本、facter/disko、nh + nix.gc。
- 桌面：GNOME + stylix（无 Hyprland）；shell 为 zsh + HM 管理的 nushell（无 fish）；无 television、无 mise、无 AppImage 打包。

### focus 维度结论（D1–D7）

- D1 flake 与质量闸门：A 用 flake-parts + import-tree + den；lock 跟踪；无 CI；`checks` 只有 statix + deadnix，没有 host eval/build gate（`CLAUDE.md` 明说 "this repo has no CI to catch eval errors"）。pin 策略与本地一致（同 channel，A 新 1 个月），质量闸门本地更强。唯一值得借的是 lock 更新前的 fleet 构建门禁（候选 A2）。
- D2 模块系统（focus）：A 的分层是 entities（hosts/users）+ aspects（feature）+ quirks（跨 aspect 数据：firewall / traefik / mimeApps / rustTargets）。host 文件只做 includes 和硬件差异；service aspect 自带端口、路由、secret、unit；networking 是独立 aspect 组。本地是 inventory 数据 + specialArgs + `modules.<x>.enable` + host imports。A 的 quirk 在本地没有等价收益：NixOS list option 本身会自动 merge，firewall/mimeApps 不需要自定义数据管道。结论：读懂 A 的分层有价值，但不迁移；无直接 D2 候选。
- D3 home-manager：A 把可变 dotfile 放仓库 `dotfiles/`，HM 用 `mkOutOfStoreSymlink` 或 activation `ln -sfn` 链接（后者专治 Claude Code 原子写 settings）。本地 HM 全声明式（claude / herdr settings 都由 HM 生成），已覆盖且更严格。无候选。
- D4 测试：A 测试成熟度「无」（无 `tests/`、无 CI，仅 lint checks）。只记录差距，不硬找候选；本地已有 nix-unit + host-eval + scan-paths + deploy checks。
- D5 secrets：A 用 sops-nix；`.sops.yaml` 单条 creation rule 覆盖 3 个 secret 文件，recipients = YubiKey PGP + 3 台 host age + 1 条旧共享 age。每个 recipient 可解密全部 secret，未按文件收敛 blast radius，且旧 key 未删除。本地是单 age key + manifests/secrets 两条规则。结论：A 不是最小权限范本；唯一可讨论的是 host SSH key 作 recipient（候选 A3，blocked）。
- D6 打包：A 用 perSystem packages、通用 AppImage wrapper（`_lib/appimage.nix`）、自维护 flake inputs；本地已有 overlay + nvfetcher + pkgs/，无 AppImage 需求。无候选。
- D7 工程化：A 有 justfile、CLAUDE.md、`docs/new-host.md`、nh；本地已有 Taskfile、APM 指令、nixos-anywhere 脚本、nh。无候选。

## 1. 已有跳过

| 做法 | 本地对应 | 结论 |
|------|---------|------|
| import-tree 自动导入 + dendritic 单文件模块 | `lib/default.nix:22-35` 的 `scanPaths`；`modules/nixos/infra/default.nix:3`、`home/base/default.nix:3` 等按目录自动 import | 已有等价自动导入；全量 dendritic 迁移无收益（见第 3 节） |
| `nix flake check` 挂 statix / deadnix | `.pre-commit-config.yaml:233-248,296-301`；`.github/workflows/pre-commit.yml:33` | 已有，且 CI 与本地同源 |
| host-eval 契约检查 | `outputs/default.nix:214-275`（`builtins.seq` 剥离 store context，只 eval 不 build） | 本地领先；A 无此能力 |
| nix-unit / scan-paths 测试 | `tests/default.nix`、`tests/nix-unit/host-metadata.nix`、`tests/real-scan-paths-test.nix` | 本地领先；A 无测试目录 |
| deploy-rs + inventory 生成 deploy nodes | `lib/inventory/utils.nix:57-181`、`outputs/x86_64-linux/src/nixos-homelab.nix:63-71` | 已有（本地多 group / 多节点模型更完整） |
| nixos-facter + disko + nixos-anywhere 刷机 | `lib/facter.nix`、`hosts/nixos-usb/disko.nix`、`hosts/_base/nixos-vps/disko.nix`、`.taskfile/nix/Taskfile.nixos-anywhere.yml` | 已有（A 的 `docs/new-host.md` 是文档化版本） |
| sops-nix `neededForUsers` / `sops.templates` | `secrets/default.nix:68-76`、`home/base/AI/dsh.nix:174` | 已有；A 的 `format="dotenv"/"binary"` 本地无消费方 |
| nh clean + 定时 nix.gc | `home/core/infra/nh.nix:51-64`、`modules/nixos/infra/nix-tools.nix:61-67` | 已有 |
| CLAUDE.md 式的命令守则与架构文档 | `.apm/instructions/dotfiles.instructions.md:11-137` | 已有，且比 A 更细（含禁止自动 deploy、Linear 流程） |
| task runner 封装 nix 命令 | `Taskfile.yml` + `.taskfile/nix/*.yml` | 已有（做法不同：Taskfile vs justfile） |
| mimeApps 集中管理 | `home/nixos/xdg.nix:39-102` | 已有；A 的 quirk 是因为 den 数据不自动 merge，NixOS option 本身会 merge |
| firewall 端口声明 | 分散在 `modules/nixos/infra/singbox-server.nix:226`、`modules/nixos/ms/k3s.nix:201-210`、`modules/nixos/desktop/gnome.nix:105-109` 等 | 已有等价语义（list option 自动合并）；不需要 quirk 聚合 |
| B：dotfiles 三棵树 + `stow --no-folding` | `home/{base,core,darwin,nixos}` + HM `xdg.configFile` / `home.file` | 已有（HM 声明式更强；stow 是退步） |
| B：只跟踪手维护文件、生成文件 ignore | HM 生成 + `.gitignore` / `.stow-local-ignore` 的同类目的 | 已有 |
| B：Arch 安装脚本 + 包列表 | NixOS modules + HM packages | 已有（Nix 声明式替代 paru 列表） |

## 2. 候选清单

| id | 维度 | 做法（它怎么做的） | 证据 | 关系 | 本地落点 | 改法 | 验证 | 收益 | 成本 | 优先级 | 状态 |
|----|------|------------------|------|------|---------|------|------|------|------|--------|------|
| A1 | D2 模块系统 | 桌面 aspect 给 nix-daemon 做资源治理：限制 max-jobs/cores，设 `daemonCPUSchedPolicy = "idle"` / `daemonIOSchedClass = "idle"`，用 `systemd.services.nix-daemon.serviceConfig` 的 `MemoryHigh`/`MemoryMax` 把构建 cgroup 笼住，并开 `systemd.oomd.enableUserSlices`；服务器另用 max-jobs=2/cores=2 + batch/idle | `modules/desktop/nix-daemon.nix:3-30`、`modules/hosts/nyx/default.nix:37-46` | 改进 | 新增 `modules/nixos/desktop/nix-daemon.nix`（`modules/nixos/desktop/default.nix` 的 `scanPaths` 会自动导入）；在 `hosts/nixos-ws/default.nix` 的 `modules.desktop.*` 打开 | 新增 `modules.desktop.nix-daemon.enable` option；保留本地全局 `max-jobs = 5 / cores = 2`，只补 daemon cgroup 上限（按主机 RAM 的 55%–65% 定 `MemoryHigh`，略高定 `MemoryMax`）和 `systemd.oomd.enableUserSlices = true`；可选 `daemonCPUSchedPolicy = "idle"` 让构建给交互让路。不要照搬 A 的 18G/22G，先看 `hosts/nixos-ws/hardware.nix` 的内存 | `nix eval --impure .#nixosConfigurations.nixos-ws.config.systemd.services.nix-daemon.serviceConfig.MemoryMax`；`nix eval --impure .#nixosConfigurations.nixos-ws.config.systemd.oomd.enableUserSlices`；再跑一次大包构建，观察 `systemd-cgtop` 与桌面流畅度、`journalctl -u nix-daemon` 有无 OOM | 中 | 低 | P1 | ready |
| A2 | D1 flake 与质量闸门 | 自托管 nightly gate：定时 `nix flake update`，逐个构建所有 host 的 `system.build.toplevel`，全部成功才 commit/push 更新后的 `flake.lock`，失败则不提交并报错；构建产物再 push 到 Attic | `modules/homelab/atticd-builder.nix:51-101`（host 列表、逐 host `nix build`、失败不提交、成功后 commit lock） | 新增 | `.github/workflows/update-flake-lock.yml`（现有 lock PR 流程）+ 可复用 `.github/workflows/flake-check.yml` 的 runner 配置 | 在 lock 更新 PR 上增加 build-gate job：至少 `nix build --no-link --accept-flake-config .#nixosConfigurations.nixos-homelab.config.system.build.toplevel` 与 `.#nixosConfigurations.nixos-vps-dev.config.system.build.toplevel` 两个代表 host（或按 PR label 选择 host），全绿才允许合并；不引入 Attic（本地无 binary cache 服务），只借「先构建再提交 lock」的约束 | 用 `workflow_dispatch` 在测试分支跑一次；打开 lock PR 后 `gh pr checks <n>` 确认 build-gate 出现且失败路径会阻塞合并；本地可先用同一命令手工验证一个 host | 中 | 高（CI 构建时间） | P2 | ready |
| A3 | D5 secrets | 用每台主机的 SSH host key（转 age 公钥）作为 sops recipient，sops-nix 激活时直接拿 host key 解密，减少单独 age key 文件的分发；编辑侧另留 YubiKey PGP key | `.sops.yaml:1-14`（hades/zagreus/nyx 三条 age + 旧共享 key）、`modules/secrets/sops.nix:1-16` | 替换 | `.sops.yaml` + `secrets/default.nix` | 收集各 NixOS host 当前的 SSH host key 公钥，逐条加入 `creation_rules` 的 age 列表；用 `sops updatekeys` 重加密现有 secrets；过渡期保留本地 age key 作为编辑/回退 key。不要删除旧 recipient，直到所有 host 验证可解密 | 在目标 host 上 `SOPS_AGE_SSH_PRIVATE_KEY_FILE=/etc/ssh/ssh_host_ed25519_key sops -d secrets/secrets.yaml >/dev/null`；重启后检查 `/run/secrets` 与 activation 日志 | 中 | 中高 | P2 | blocked |

## 3. 看看就好

| 做法 | 不吸收理由 |
|------|-----------|
| den / dendritic 全量迁移（entities + aspects + policies） | 会重写 hosts/outputs/deploy-rs/CI 全套接线；本地已有 inventory + host-eval + nix-unit + deploy-rs，收益不抵成本。A 的优势主要在跨 nixos/HM 的 aspect 组合，本地模块边界已清晰，迁移属于架构赌博 |
| den quirks 数据管道（firewall / traefik / mimeApps / rustTargets） | NixOS list option 本身自动 merge，A 需要 quirk 是因为 aspect 数据不经过 module system；本地分散声明已等价。为审计便利引入自定义 namespace 收益太低 |
| homelab 服务 aspect 自带 Traefik 路由 + 端口 + unit（atticd / glance / technitium / actual） | 本地 homelab 走 k3s/Flux manifests，服务不在 Nix 里定义；换服务模型成本远大于收益。仅「service 自己声明端口」这一点本地已做到 |
| `_` 前缀手动 import 约定（`_lib/appimage.nix`、`_hardware-configuration.nix`） | 本地已有 `scanPaths` + `lib/` 放 helper；再引入第二套前缀规则只增加认知成本 |
| 通用 AppImage wrapper（`_lib/appimage.nix`） | 本地无 AppImage 应用需求；`modules/nixos/kernel/fhs.nix` 已覆盖运行 AppImage 的 FHS 环境 |
| 仓库内 `dotfiles/` + `mkOutOfStoreSymlink` / activation `ln -sfn` 管理 app 可变配置 | 本地 claude/herdr/vicinae 配置都由 HM 声明式生成，没有需要 app 回写的配置文件。若未来出现，优先用 `home.activation` + `ln -sfn`，避开 `mkOutOfStoreSymlink` 的原子写陷阱（A 的注释已给出踩坑记录） |
| nyx 的专用 `ops` 管理用户（key-only + passwordless sudo） | 本地 root 和 luck 都已带 fleet SSH key 且 luck 在 wheel；再加一个 sudo 路径不会缩小 blast radius，除非同时把 luck 移出服务器 wheel，单用户 fleet 收益低 |
| YubiKey PGP 作为额外 sops 编辑 key | 本地 age recipient 仍可解密全部文件，blast radius 不变；只增加编辑便利，却引入 gpg/智能卡依赖 |
| 自托管 Attic + 夜间构建推送 | 本地无 binary cache 服务；引入需要新主机/存储/密钥分发，收益被现有 GitHub CI 部分覆盖 |
| alejandra formatter | 本地 treefmt 统一用 nixfmt（`.github/linters/treefmt.toml`），不切换 |
| B：`stow --no-folding` + common/linux/macos 三棵树 | HM 已声明式管理 dotfile，stow 会退回手工 symlink，无法接 sops/CI/回滚 |
| B：Hyprland Lua 模块 + `.luarc.json` stubs + hyprmoncfg 生成 monitors.lua | 本地桌面是 GNOME（`hosts/nixos-ws/default.nix:128-151`），无 Hyprland；同套 Lua 方式 A 已 Nix 化，真要用时参考 A 而非 B |
| B：television cable channels + zellij-sesh | 本地未安装 television；这是工具选型，不是可吸收的工程实践。若引入 television，再参考 B 的 channels 和 A 的 `modules/packages/zellij-sesh.nix` |
| B：mise 固定 node/bun/deno 大版本 | 本地 runtime 由 Nix/HM（`home/base/langs/*`）提供；再加 mise 会形成双版本源 |
| B：theme-switch 脚本 + alacritty `current.toml` 切换 | 本地用 stylix 声明式主题；运行期脚本切换与声明式目标冲突 |
| B：fish / nushell 手写配置与 `.stow-local-ignore` 白名单 | 本地 shell 是 zsh + HM 管理的 nushell，配置在 `home/core/kernel/zsh.nix` 内联生成；B 的 stow 白名单模式不适用 |
| B：`.claude/skills/wiki-troubleshoot` | 面向 Arch/CachyOS 的排障 skill，本地是 NixOS；本地已有自己的 skills 管道（`home/base/AI/skills`） |
| B：`install/install.sh` + `packages/*.packages` | Arch/paru 专用；NixOS 由 modules/HM 声明包集合 |

## 4. blocked

| 候选 | 阻塞原因 | 前置条件 |
|------|---------|---------|
| A3：host SSH key 作 sops age recipient | 需要重加密所有现有 secrets；darwin / sm-vps 没有系统级 host key 路径；迁移期任一 host key 不匹配会导致激活时解密失败（secrets 锁死）。A 自己的 `.sops.yaml:12-13` 还留着「旧共享 key：等所有 host 切换后再删」，说明这条迁移路本身未完成 | 先盘点所有 NixOS host 的当前 host key；保留现有 age key 作为编辑/回退 recipient；在单台非关键 host 上验证通过后再逐台切换；darwin/sm-vps 继续走 age key 文件路径 |

## 5. 一句话结论

从 A 仓库最值得吸收的是两条运行层实践：给桌面 host 的 nix-daemon 加 cgroup 内存笼子（A1），以及让 flake.lock 更新必须经过 fleet 构建门禁（A2）；den/dendritic 架构本身对本地是负收益。B 无 Nix/HM 集成，stow 模型已被本地 HM 取代，无可吸收项。

## 规范摩擦点

- 单 repo 模板承载「同作者两 repo 一组」：section 0 的 pin / 规模 / 架构摘要只有一个字段，phase 0 又要求「读目标 repo 的 flake.nix」，对没有 flake 的 B 没有降级写法；本次自行扩展为 A/B 双锚定。
- 精读上限（文件数 >200 或行数 >5000 时最多 30 个）未说明按 repo 还是按组计算；本次按「A 30 个核心文件 + 小模块片段、B 10 个关键文件」执行，并在报告里标注其余为结构推断。
- flake.lock 的 node 名不能直接当 input 名：A 的 root `nixpkgs` 指向 `nixpkgs_4`，同名 `nixpkgs` 是 bun2nix 引用的 tarball 节点；规范只写「记 nixpkgs rev」，容易误读。
- 候选表没有 `blocked_by` 列，blocked 候选只能在第 4 节重复写阻塞原因；建议模板表加一列或在 status 里引用 id。
- D4「成熟度为无时只记录差距」与 D1「无 CI / 无 checks 是合法结论」会让工程实践型 repo 在候选表里天然为空；本次 A 的候选全部落在运行实践（D1/D2/D5）而非测试。
