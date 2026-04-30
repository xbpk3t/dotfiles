---
title: mihomo
date: 2026-04-30
isOriginal: false
---


:::tip[TLDR]

singbox配置太麻烦了，且经常出现各种小毛病，可以看到之前对于singbox问题的排查：

- [singbox-darwin-wake-recovery-followup](./2026-03-22-singbox-darwin-wake-recovery-followup.md)
- [singbox-high-cpu-review](./2026-04-05-singbox-high-cpu-review.md)
- [singbox-rule-fakeip-private-ip-conflict-review](./2026-04-17-singbox-rule-fakeip-private-ip-conflict-review.md)


---

简单来说就两点：

- 1、配置更简单。clash(mihomo) 要比 singbox 简单很多，下限更高，更不容易出现配置错误。
- 2、更主流。clash相比 singbox 更主流（或者说用的人更多，更通用）





:::



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







#### ***mihomo是否支持 vless***

:::tip

支持，但不完全支持。

- 1、旧版mihomo不支持vless，在 ``之后支持。
- 2、默认不支持 vless，需要在build时添加tags

:::


---






```markdown
需要你给我一个判断，mihomo是否支持 vless+reality 作为出站和入站

需要真正查到相关文档，再给我判断，不要瞎猜

```



结论：**mihomo 现在支持 VLESS + Reality 作为出站，也支持作为入站。**


**1. 出站 outbound：支持。**
官方 VLESS 出站文档在 `proxies:` 示例里明确给了：

```yaml
type: vless
flow: xtls-rprx-vision
tls: true
servername: example.com
reality-opts:
  public-key: xxxx
  short-id: xxxx
network: tcp
```

这就是典型的 **VLESS + TLS + Reality** 客户端/出站配置；`reality-opts` 出现在 VLESS 出站配置中，足以判断 mihomo 支持把 VLESS+Reality 用作出站代理

**2. 入站 inbound/listener：也支持。**
官方 VLESS listener 文档在 `listeners:` 示例里明确给了：

```yaml
type: vless
users:
  - uuid: ...
    flow: xtls-rprx-vision

reality-config:
  dest: test.com:443
  private-key: ...
  short-id:
    - 0123456789abcdef
  server-names:
    - test.com
```

并且文档写明“如果填写 `reality-config` 则开启 reality”，同时说明 VLESS listener 至少需要 `certificate/private-key`、`reality-config` 或 `decryption` 三者之一。也就是说 mihomo 可以作为 **VLESS+Reality 服务端入站 listener**。

需要注意两点：

第一，入站这里是 mihomo 的 **`listeners` 入站**，不是传统 Clash 只做本地 HTTP/SOCKS 入站的那种语义；它确实可以监听 VLESS。官方目录里 VLESS 同时出现在“入站 listeners”和“出站代理 proxies”下。

第二，最好使用较新的 mihomo core。官方页面显示 VLESS 出站页更新到 **2026-04-01**，VLESS listener 页更新到 **2026-04-20**；如果你用的是旧版 Clash.Meta/mihomo，尤其是旧 GUI 内置 core，可能不支持或字段不完整。



| 场景                           | mihomo 是否支持 VLESS+Reality |
| ---------------------------- | ------------------------- |
| 作为出站 client / outbound proxy | **支持**                    |
| 作为入站 server / listener       | **支持**                    |
| 旧版 core                      | **不保证，需要看版本**             |


---









#### mihomo的vless和hy2不支持端口复用

mihomo不支持类似 singbox的 vless 和 hy2 的 port复用。必须要使用各自的port

[fix(mihomo): 收尾 mihomo 相关配置 · xbpk3t/dotfiles@176d0ed](https://github.com/xbpk3t/dotfiles/commit/176d0edf955fd5bfd36bdbdc28bf9cef10c1aa1b)





#### 为啥选择 mihomo裸核+metacubexd

原本的打算是直接在 `darwin/mihomo-client.nix` 里直接用 `home.activication` 把我自己的 mihomo config 固定到 `~/.config/clash` 就行了，然后 `clashx-pro`这个GUI，就可以直接切换不同 `config.yml` 使用了，更灵活。

但是GUI会报错


```log
Reload Config Fail

Proxy 0: unsupport proxy type: vless

```

并且我发现现在 `clashx-pro`版本很乱，不支持 brew安装

[ClashX-Pro/ClashX: Clash X](https://github.com/ClashX-Pro/ClashX)







### 2.4 原则总结

**用复杂度匹配问题的工具。** Mihomo 226 行的配置库解决了和 singbox 300+ 行同样的代理需求。不是因为 mihomo "更好"，而是这个场景（几个 VPS 节点、VLESS+HY2、简单的国内外分流）不需要 singbox 的复杂度。日常用简单的，复杂场景用功能全的，两者共存。

**共享数据，不共享配置。** Inventory 驱动的模式（一份数据 → 多套工具配置）消除了配置漂移。这是整个代理架构里最有价值的决策。

**macOS 上 launchd 优先于 activationScripts。** 经过两轮静默丢配置和一次构建缓存谜案，结论很明确：nix-darwin 的 launchd 集成比 activation script 系统更可靠。

**DynamicUser 冲突是 nixpkgs module 设计异味。** 如果一个 module 用了 `DynamicUser`，但你的场景需要在服务启动前就让用户/组存在（比如为文件设权限），那这个 module 就不干净地支持你的需求。这是"安全默认"和实际部署需求之间的常见冲突。

## ***3. Mihomo vs Singbox***

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




```markdown
可以，但我会把结论说得稍微收一点：

**如果只谈“裸核服务本身的配置文件”，并且场景是做一个常规的代理/分流服务，那么大体上可以认为 mihomo 的配置比 sing-box 更容易上手，配置下限更高，也更不容易因为抽象层太多而配错。** 不过“简单很多”有点说过头；更准确的说法是：**mihomo 更顺手，sing-box 更体系化但也更挑人。** ([虚空终端][1])

原因主要有三点。

第一，**mihomo 的配置模型更贴近传统 Clash 的直觉**。官方文档明确说 mihomo 支持原 Clash 的全部特性，文档目录也是按用户最熟悉的几块来拆：全局配置、DNS、入站、出站代理、代理集合、代理组、路由规则、规则集合。像 `proxy-providers`、`proxy-groups`、`rules` 这些概念都是直接暴露给你，用 YAML 写出来也基本是一眼能看懂的结构；路由规则还是典型的“自上而下匹配”。这会让“写出一个能跑的配置”这件事更直接。([虚空终端][1])

第二，**sing-box 的配置抽象更统一，但对象层次更多**。它的顶层结构里就有 `log`、`dns`、`certificate`、`certificate_providers`、`endpoints`、`inbounds`、`outbounds`、`route`、`services`、`experimental` 这些模块；规则又进一步拆成 `rule_set`、`action`、逻辑规则、匹配语义等。官方文档里甚至专门说明默认规则的组合逻辑是多组条件的 AND/OR 关系，而不是单纯“写一条规则就匹配一条”。这类设计对可组合性很好，但对很多人来说，**更容易出现“字段放对了位置但语义没对上”的错误**。([Sing Box][2])

第三，**sing-box 近几个版本的配置演进确实更频繁**。官方迁移指南从 1.8.0 一直到 1.14.0，列出了多轮迁移：GeoIP/Geosite 迁移到规则集、旧特殊出站迁移到规则动作、DNS 服务器格式变化、TUN 地址字段合并等；官方还写明 `geosite` 在 1.8.0 已废弃、1.12.0 移除，`outbound` 字段在路由规则里也已于 1.11.0 废弃并迁移到 `action`。这意味着你今天“能工作”的 sing-box 配置，未来版本里更容易遇到迁移成本。相比之下，mihomo 虽然也在扩展，但从配置表达方式看，整体延续性更强。([Sing Box][3])

但也得给 sing-box 说句公道话：**它不一定更容易“语法报错”**。因为官方直接提供了 `sing-box check`、`sing-box format` 和 `sing-box merge` 这类命令，工具化比 mihomo 官方文档里体现出来的要完整。也就是说，**从“语法校验”层面，sing-box 反而更严谨；它更容易出问题的地方，通常不是 JSON 少了个逗号，而是配置模型本身更抽象、版本迁移更多。** ([Sing Box][2])

所以我的最终判断是：

**能。**
但建议表述成：

**对大多数裸核部署者来说，mihomo 的配置心智负担更低、容错更高；sing-box 不是单纯“更难”，而是更工程化、更显式，也因此更容易让非深度用户在配置结构和版本迁移上踩坑。** ([虚空终端][1])

再压缩成一句话就是：

**mihomo 更像“容易写对的工具”，sing-box 更像“表达力更强但需要更清楚自己在做什么的框架”。** ([虚空终端][4])

你要是愿意，我可以下一条直接把两者在“同样实现一个最普通的 TUN + DNS + 分流服务”时，配置复杂度逐项拆开。

[1]: https://wiki.metacubex.one/ "虚空终端 Docs"
[2]: https://sing-box.sagernet.org/configuration/ "Introduction - sing-box"
[3]: https://sing-box.sagernet.org/zh/migration/ "迁移指南 - sing-box"
[4]: https://wiki.metacubex.one/config/proxy-providers/ "代理集合配置 - 虚空终端 Docs"

```
