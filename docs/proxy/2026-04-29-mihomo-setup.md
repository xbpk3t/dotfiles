# 为 Dotfiles 添加 Mihomo：第二套代理栈的完整实践

## 1. 为什么需要 Mihomo

### Singbox 的问题

Singbox 在这个仓库里跑了几个月，一直很稳。它的协议覆盖很全（VLESS、Hysteria2、TUIC、ShadowTLS、WireGuard），DNS 和路由模型做得很细，支持外部规则集动态更新，上游迭代也很活跃。

但作为仓库里唯一的代理方案，它有几个问题：

- **配置复杂，改起来心理负担大。** `lib/singbox/` 下面有五个文件（config、ruleset、route、dns、outbounds），再加上 Darwin/NixOS 两套密钥注入方式的差异（placeholder vs `_secret`），每次加节点或调路由规则都要在多个文件间跳转。这种摩擦会让人在改代理配置之前多犹豫几秒——而这几秒往往就意味着"算了不优化了"。

- **出问题时排错链路长。** 一旦挂了（而这种事确实发生过，参见 [高 CPU 排查](./2026-04-05-singbox-high-cpu-review.md) 和 [睡醒断网修复](./2026-03-20-singbox-darwin-wake-recovery.md)），你要同时排查 singbox 的 config parser、DNS 解析链、TUN 栈，以及 Nix module 层的封装。定位根因很慢。

- **没有快速逃生通道。** 如果 server 端的配置出了问题，所有 client 节点一起断网。能切到外部机场节点算是备用方案，但这需要提前配好，而且切起来也麻烦。

### Mihomo 解决了什么

引入 Mihomo (Clash Meta) 作为并行代理栈：

1. **冗余。** 两套代理工具、两套 inbound、两个独立 daemon。一个挂了，另一个照跑。
2. **简单。** Mihomo 的配置结构更扁平。整个 client config（DNS、规则、TUN、代理组、proxies）在一个 158 行的文件里搞定。没有 Darwin/NixOS 的密钥注入分叉——所有平台统一走 sops placeholder。
3. **代理组。** 内置的 `url-test` 代理组会自动挑最快的节点走，这是 singbox 原生不支持的能力（需要外部工具配合）。

目标不是替换 singbox，而是**两者共存**，共享同一份 inventory 和 secrets，选哪个代理工具变成一个 host 配置里的单行修改。

## 2. 具体实现

### 2.1 架构总览：一份 Inventory，两套代理栈

核心设计：singbox 和 mihomo 从同一份数据源读取。

```
inventory (data.nix)
  ├── singboxForHost(...)  ──→  lib/singbox/  ──→  sops  ──→  sing-box daemon
  └── singboxForHost(...)  ──→  lib/mihomo/   ──→  sops  ──→  mihomo daemon
```

`singboxForHost` 函数原本是为 singbox 写的，负责从 inventory 提取每个节点的元数据：server IP、HY2 域名、端口、TLS 配置等。让 mihomo 复用同一个函数，**元数据一致性是天然的**——你在 inventory 里改一个 server IP，singbox 和 mihomo 的配置会同时更新。

配置生成的流水线是：

1. `lib/mihomo/outbounds.nix` —— 把 inventory 节点数据翻译成 mihomo 格式的 proxy 条目（字段名和 singbox 不同：`port` 而不是 `server_port`、`servername` 而不是 `tls.server_name` 等）。
2. `lib/mihomo/client-config.nix` —— 组装完整 client config（DNS、TUN、规则、代理组），密钥用 sops placeholder 占位。
3. `sops.templates` —— 运行时替换真实密钥（不进 `/nix/store`）。
4. 平台级 module 把 config 接给 daemon。

### 2.2 实现过程

改动涉及三个平台：

**VPS Server**（`modules/nixos/vps/mihomo-server.nix`，137 行）。双协议 inbound：VLESS+Reality 在 8443 端口，Hysteria2 配 ACME 自动签发 TLS 证书。使用 nixpkgs 的 `services.mihomo` 但覆盖 systemd unit，把 `DynamicUser` 换成静态用户（原因见 2.3）。

**macOS Client**（`modules/darwin/mihomo-client.nix`，56 行）。单 launchd daemon：启动时用 `yq-go` 把 sops 渲染的 JSON 转成 YAML，然后 exec mihomo 进 TUN 模式。Metacubexd 做 Web UI，地址 `http://127.0.0.1:9090`。

**NixOS Client**（`modules/nixos/extra/mihomo-client.nix`，51 行）。直接用 nixpkgs 的 `services.mihomo`，绑定 `systemd-networkd` 生命周期防止 TUN 路由在 networkd 重启后丢失。

在 host 层，切换代理工具是一行 diff：

```nix
# 之前
singbox.enable = true;

# 之后
singbox.enable = false;
mihomo.enable = true;
```

### 2.3 踩坑记录

#### activationScripts 类型陷阱：配置被静默丢弃

macOS 侧第一版用了 `system.activationScripts` 把渲染好的配置拷到 `~/.config/clash/`。`nix eval` 阶段一切正常，脚本内容正确。但部署后的系统里就是没有这个文件——没有报错，没有 warning，配置凭空消失了。

**根因：** nix-darwin 的 `system.activationScripts.<name>` 要求 submodule 类型（带 `text` 字段），不接受裸字符串：

```nix
# 错误 —— 被类型系统静默丢弃
system.activationScripts.mihomoConfig = ''...'';

# 正确
system.activationScripts.mihomoConfig.text = ''...'';
```

NixOS 两种写法都接受，但 nix-darwin 不行。类型不匹配导致 option 在 merge 阶段被拒绝，但不会产生任何可见的错误信息。

**解决：** 改用 `launchd.daemons`，这是 macOS 原生且已验证的模式（singbox 就在用）。Launchd daemon 会产生独立的 `.plist` 文件，Nix 会将其作为 derivation 输入正确追踪。

**教训：** nix-darwin 上优先用 `launchd.daemons` 而不是 `system.activationScripts` 来做配置生成。

#### DynamicUser 与静态用户冲突：217/USER

VPS server 需要 mihomo 用户/组在 ACME 之前就存在（证书目录需要 `chgrp mihomo`）。于是加了 `users.groups.mihomo = {}`，部署直接报错：

```
mihomo.service: Failed to update dynamic user credentials: User or group with specified name already exists.
mihomo.service: Failed at step USER spawning .../mihomo: Operation not supported
status=217/USER
```

**根因：** nixpkgs 的 `services.mihomo` 在 systemd service 里用了 `DynamicUser = true`。systemd 会在服务启动时动态创建 "mihomo" 用户，但我们已经建了一个同名的静态组。冲突产生 exit code 217。

Singbox 的 nixpkgs module 没有这个问题——它从一开始就用静态用户（`users.users.sing-box = {...}`）。

**解决：** 禁用 `DynamicUser`，创建静态用户和组，调整数据目录路径（`/var/lib/private/mihomo` → `/var/lib/mihomo`），并加上 `ReadOnlyPaths = ["/var/lib/acme"]`（因为 `ProtectSystem = "strict"` 会用 tmpfs 遮住 `/var`，证书目录不可见）。

```nix
users.users.mihomo = { isSystemUser = true; group = "mihomo"; };
users.groups.mihomo = {};

systemd.services.mihomo.serviceConfig = {
  DynamicUser = lib.mkForce false;
  User = "mihomo";
  Group = "mihomo";
  ExecStart = lib.mkForce (...);  # -d /var/lib/mihomo 替代 /var/lib/private/mihomo
  ReadOnlyPaths = ["/var/lib/acme"];
};
```

**教训：** 任何 nixpkgs module 用了 `DynamicUser` 时，不要再创建同名的静态用户或组。要么彻底禁用 `DynamicUser`（连带处理路径和权限的级联影响），要么换一种方式解决原始需求（比如用 supplementary group 替代）。

#### git+file:// Flake 构建缓存

提交代码后，`nix eval` 显示 activation script 正确（包含 `yq-go`），但 `nix build` 产出的 store path 和改动前一模一样。derivation hash 完全没变，尽管配置内容明明改了。

**根因：** `system.activationScripts.<name>.text` 作为字符串存储在 derivation 内部，而 nix-darwin 的构建机制不会因为这个字符串变化而更新 toplevel derivation 的 hash。改用 `launchd.daemons`（产出独立 `.plist` derivation）后问题消失——因为 `.plist` 文件的 store path 变了，toplevel derivation 依赖它的 hash 也跟着变。

**验证方法：** 切换前，`nix derivation show` 查看 toplevel `.drv` 的 inputDrvs，没有 mihomo 相关条目。切换后，多了一个 `launchd.drv`。

**教训：** nix-darwin 下 `system.activationScripts` 的文本变更不能可靠触发构建缓存失效。如果 build 结果没变，用 `nix derivation show` 查看 `.drv` 文件的输入图谱，确认你的改动是否真的出现在里面。

### 2.4 原则总结

**用复杂度匹配问题的工具。** Mihomo 226 行的配置库解决了和 singbox 300+ 行同样的代理需求。不是因为 mihomo "更好"，而是这个场景（几个 VPS 节点、VLESS+HY2、简单的国内外分流）不需要 singbox 的复杂度。日常用简单的，复杂场景用功能全的，两者共存。

**共享数据，不共享配置。** Inventory 驱动的模式（一份数据 → 多套工具配置）消除了配置漂移。这是整个代理架构里最有价值的决策。

**macOS 上 launchd 优先于 activationScripts。** 经过两轮静默丢配置和一次构建缓存谜案，结论很明确：nix-darwin 的 launchd 集成比 activation script 系统更可靠。

**DynamicUser 冲突是 nixpkgs module 设计异味。** 如果一个 module 用了 `DynamicUser`，但你的场景需要在服务启动前就让用户/组存在（比如为文件设权限），那这个 module 就不干净地支持你的需求。这是"安全默认"和实际部署需求之间的常见冲突。

## 3. Mihomo vs Singbox

### 配置对比

| 维度 | Mihomo | Singbox |
|------|--------|---------|
| Client 配置 | 1 个文件，158 行 | 5+ 个文件，300+ 行 |
| 规则格式 | `"DOMAIN-SUFFIX,google.com,Proxy"` | `{domain_suffix: "google.com", outbound: "proxy"}` |
| DNS 模型 | fake-ip（内置） | 显式 DNS 规则 + 路由 |
| TUN 配置 | 4 行 | 10+ 行（含 address/mtu/nat） |
| 代理组 | 内置 select / url-test | 不支持 |
| 密钥处理 | 统一路径（sops placeholder） | 平台分叉（placeholder vs `_secret`） |

### 什么时候用哪个

**用 Mihomo：**
- 节点数量少且稳定（≤10 个）
- 需要节点间自动故障切换（url-test）
- 配置简洁比精细控制更重要
- 不需要 VLESS/Hysteria2/SS 之外的协议

**用 Singbox：**
- 需要外部规则集独立于配置更新
- 需要逐连接的 DNS 解析控制
- 用到 VLESS/Hysteria2 之外的协议（TUIC、ShadowTLS、WireGuard）
- 需要 TUN 层精细调参（MTU、strict route、endpoint-independent NAT）

**两者可以共存。** Inventory 驱动的架构让同时跑两套代理变成 host 配置里的单行改动。这才是真正的收益：不需要永远选边站。日常用 mihomo 的简单和自动故障切换，singbox 保持配置作为兜底和极端场景的备选。






```log
Reload Config Fail

Proxy 0: unsupport proxy type: vless

```




```markdown
➜ systemctl status mihomo.service
● mihomo.service - Mihomo daemon, A rule-based proxy in Go.
     Loaded: loaded (/etc/systemd/system/mihomo.service; enabled; preset: ignored)
     Active: active (running) since Tue 2026-04-28 22:43:00 CST; 10h ago
 Invocation: 9a81ecd481344c1cb6feeb7bb530ee02
       Docs: https://wiki.metacubex.one/
   Main PID: 32081 (mihomo)
         IP: 0B in, 0B out
         IO: 0B read, 16K written
      Tasks: 12 (limit: 14745)
     Memory: 7.1M (peak: 11.5M)
        CPU: 25.691s
     CGroup: /system.slice/mihomo.service
             └─32081 /nix/store/1qq8f9gq0w46hfjqkf9cawj7m6finm2b-mihomo-1.19.24/bin/mihomo -d /var/lib/mihomo -f /run/credentials/mihomo.service/config.yaml

Apr 28 22:43:00 nixos-vps-dev systemd[1]: Starting Mihomo daemon, A rule-based proxy in Go....
Apr 28 22:43:00 nixos-vps-dev (mihomo)[32081]: mihomo.service: Found pre-existing private StateDirectory= directory /var/lib/private/mihomo, migrating to /var/lib/mihomo.
Apr 28 22:43:00 nixos-vps-dev (mihomo)[32081]: mihomo.service: Apparently, service previously had DynamicUser= turned on, and has now turned it off.
Apr 28 22:43:00 nixos-vps-dev systemd[1]: Started Mihomo daemon, A rule-based proxy in Go..
Apr 28 22:43:00 nixos-vps-dev mihomo[32081]: time="2026-04-28T22:43:00.531764490+08:00" level=info msg="Start initial configuration in progress"
Apr 28 22:43:00 nixos-vps-dev mihomo[32081]: time="2026-04-28T22:43:00.532823397+08:00" level=info msg="Geodata Loader mode: memconservative"
                                                                        Apr 28 22:43:00 nixos-vps-dev mihomo[32081]: time="2026-04-28T22:43:00.532935797+08:00" level=info msg="Geosite Matcher implementation: succinct"
Apr 28 22:43:00 nixos-vps-dev mihomo[32081]: time="2026-04-28T22:43:00.533531041+08:00" level=info msg="Initial configuration complete, total time: 1ms"
Apr 28 22:43:00 nixos-vps-dev mihomo[32081]: time="2026-04-28T22:43:00.688506729+08:00" level=info msg="Sniffer is closed"
Apr 28 22:43:00 nixos-vps-dev mihomo[32081]: time="2026-04-28T22:43:00.689757656+08:00" level=info msg="Start initial compatible provider default"
```


[ClashX-Pro/ClashX: Clash X](https://github.com/ClashX-Pro/ClashX)
