---
title: 网络代理使用总结
slug: /2026/proxying-in-practice
date: 2026-03-23
tags:
  - sing-box
---

:::tip[前情提要]

目前方案的设计是基于以下场景（需求&约束）：

- 个人使用，不需要多人使用的附加功能

- 多端使用，不只是单机
- 既有 macOS / NixOS 差异
- 想减少 GUI 客户端依赖
- 需要可维护、可迁移、可自动更新
- 未来可能同时覆盖 client / server

:::

## 简要介绍我的singbox方案

:::tip

这部分介绍我当前singbox相关的整套方案，以及说明为什么这么设计

- 【技术选型】为啥选择singbox而非clash
- server
  - 为啥用 nix 配置 singbox server（而非直接用别人的shell）
  - 为啥用 vless? 具体查看 [代理协议](#代理协议)
- client

:::

### server

:::danger

简单来说，目前最简单实用的方案就是直接选择DMIT之类的靠谱服务商的美西节点（LA或者）进行自建

:::

#### 为啥用 nix 配置 server（而非直接用第三方shell）

目前大部分人自建都直接使用以 [233boy/sing-box](https://github.com/233boy/sing-box) 为代表的shell进行安装（与其对标的repo还有【qljsyph/sbshell】、【eooce/Sing-box】、【mack-a/v2ray-agent】、【yonggekkk/sing-box-yg（支持一些拓展功能（Argo/WARP/Psiphon、多内核混合））】。【alireza0/s-ui】、【beck-8/subs-check（订阅转换、测速、测活、流媒体检测、重命名、导出为任意格式的工具）】）

之前考虑过“直接用脚本安装，没必要nix化（这种机器都是买最便宜的，性能也就很差，玩不起来）直接使用 233boy/sing-box 或者 sbshell 即可”，但是为啥最终又决定nix化了呢？

其实这个仍然是一分为二

#### 为什么不考虑打野？

[全自动获取免费机场节点/订阅方法分享【立即实现代理节点自由】 - 开发调优 / 开发调优- LINUX DO](https://linux.do/t/topic/38413)

[让自动获取免费机场订阅更自动](https://linux.do/t/topic/93330/153)

与其自建节点，不如直接打野抓别人的节点。在自建之前先搞下这个。我感觉打野搭配 sub-store会很有用。
【翻墙的终极解决方案】
简单来说，就是 打野/机场 和 自建 互为灾备、互为冗余，具体来说，打野+自动扔进sub-store做测速（测速、筛选节点、删除无效节点等），自动按照latency排序，给我下发订阅URL（之后多端的singbox直接拉URL，本地不需要任何操作，默认使用）。
打野（做中转, GroupPool）和自建（做落地鸡, GroupSelf）互为failover，两个其中任一挂了，直接另一个走直连。
自建组两台机器，一台LA机器，DMIT大妈的的T1（我的主力落地鸡，美西节点，服务全开，¥37/年（折合来说¥12/月，比机场便宜），1C1G20GB1TB流量千兆带宽，网络好配置差，只做落地鸡（BWG 类似配置但是2C的机器$50/年）），另一台HK机器（备用落地鸡，我的主力VPS兼作落地，sub-store就在这台机器上跑，跑完把订阅URL分发到我所有workstation和homelab机器上）
我的所有机器都直接走VLAN，不走公网，所以不需要担心被人打野

```yaml
# 想法很好很天真，云端测速，多端的singbox直接吃现成的（默认latency排序，singbox默认读取第一个node）
#但是之前忽略了一点，目前sub-store是跑在HK节点的。而我所有需要跑singbox进程的端的网络环境就比较复杂了。
#所以这里这个问题的最优解是什么？是直接本地singbox测速转换节点？但是singbox cli 本身不支持这个操作，所以怎么实现呢？还是说有更好的方案？
```

### client

#### 为啥用 nix 配置 singbox client（而非使用第三方）

#### why not use wireguard-based VPN?

看到一个说法

> “突然想到，如果买了好多台线路vps，买了一台落地，是不是可以用 wireguard 或者 tailscale 连起来，落地vps 作为 exit node； 这样只要连上线路约等于自动到落地了”

有很多人认同。其实这个说法是有问题的。**_且不提tss跟sinbox来翻墙，在latency和抗封锁上做比较_**（可以比较（但是没必要比）。简单来说，tss这类方案都是UDP包，所以可以理解为类似singbox用hy2或者TUIC。但是tss不是还有个relay吗？这个情况下就不如直接vless+reality了，latency和抗封锁两方面都不如。也就是说“Tailscale 兼顾 hy2（UDP）和 vless（TCP）这两类传输思路”）。之所以说，二者没必要比，因为singbox的核心在于route和rule-set，而tss做不了这个。结论：有人说可以应急使用，在我看来，应急时随便找个节点就行了，何必用这个？

[2026-01-22] 上面说法有问题，这里写个更清晰的说法。singbox支持使用wireguard作为outbounds type，而tailscale使用exit-nodes同样可以实现fq。所以很多人误以为可以用tailscale替代singbox。实际上很简单，singbox的核心在于rule-set，而wireguard的核心则在于

## 代理协议

:::tip

这部分用来解释究竟是怎么翻墙的

:::

### GFW运行机制

```yaml
# [【安全上网】防火长城GFW史上最大规模的内部文件泄露事件，揭示GFW的运作细节，DPI深度包检测｜流量限速｜篡改网页数据｜注入恶意代码｜DDos攻击｜流量定位到个人｜重点关注对象｜普通用户应该怎么办？ - YouTube](https://www.youtube.com/watch?v=yCq_Rwpm10A)
# https://dti.domaintools.com/inside-the-great-firewall-part-1-the-dump/
# https://dti.domaintools.com/inside-the-great-firewall-part-2-technical-infrastructure/

- "***【GFW工作机制】GFW technical arch***"
  # 1、DPI（去查SNI）
  # 2、QoS (流量限速) 对于可疑但是拿不准的（对特定协议或者无法识别的加密数据降权），保证可用但是很难用
  # 3、（对于明文流量）实时注入和修改（感觉类似MMIT? 比如说访问网站时弹出反诈提醒，就是被识别到了，并且被篡改网页内容来屏蔽网站。既然如此，也可以实现对网页部分内容做实时修改，比如说把里面的代码替换为恶意代码，或者替换里面的 DMG, ZIP 之类的资源） # 从这点来说，所以一定要在浏览器开启严格模式（非HTTPS不使用）
  # 4、（根据网络流量）归因到真实身份 # 这点倒是没必要担心，不要“被标记”即可。

  #  DNS污染：抢在正确DNS服务器前返回一个错误的IP地址，导致域名无法访问。
  #  SNI阻断：在HTTPS连接建立初期，通过明文传输的服务器名称指示（SNI）来识别并阻断对特定网站的访问。
  #  IP封锁：直接将目标服务器的IP地址拉入黑名单，丢弃所有发往该IP的数据包。
  #  深度包检测 (DPI)：分析流量的数据特征，识别并干扰如 Shadowsocks、VMess 等代理协议。
  #  关键字过滤：检测流量中的敏感词，并切断TCP连接。
  #  主动探测：模仿正常用户访问可疑IP和端口，如果服务器未能返回合法的网站响应，则判定为代理并进行封锁。
```

### 代理内核（协议实现引擎）

代理工具bottom-up来说就是 代理协议 -> 代理内核 -> client。可以理解为上游、中游和下游。\*\*\*这里想表达两个观点：

1、直接用内核而非client。
2、内核应该用singbox，而非其他方案\*\*\*。

对我来说，我现在NixOS上打算直接使用代理内核，所以client的纷纷扰扰也就不考虑了（确实是纷纷扰扰，基本上都是套个Electron（mihomo-party）、Tauri（clash-verge）或者 fluter（FLClash），各种feats多一点少一点，还经常有bug，还有跟上游内核有骂战的（mihomo-party），有的还被公司收购了，后面肯定要做商业化运营，QTMD吧，我还不如直接用内核呢）。client不谈了，但其实内核可选空间也不大，总的来说就3家（clash系、v2ray系、singbox）。

X-ray是对v2ray的分叉，解决了前者新协议支持弱的问题。clash系的核心是clash-meta（Clash则是基于前者的lite版本，资源开销更低，也移除了TUN模式和高级规则集这两个功能。目前已经EOL了（因为这两个feats算是核心功能了，并且大部分clash的client都是基于clash-meta，所以继续维护clash内核意义不大了））。我不考虑用singbox，除了老生常谈的“配置频繁变更，兼容性极差”、“配置复杂”以外，singbox只支持JSON配置，我不喜欢，遂不用。【】研究了一下，使用singbox基于两点原因：

1、必须通过API调用mihomo（singbox支持command）。

2、singbox的JSON配置并不需要手动维护（通常都是机场提供URL，除非需要自己改规则、改策略组、添加自建节点）。但是这个“除非”本身就被考虑在内了，可以被 substore、sing-box-subscribe 之类的工具完美替代了。

#### 【技术选型】为啥选择singbox而非clash

### 代理协议横评

**_[2025年度代理协议"拉到夯"综合排名](https://www.youtube.com/watch?v=IoFtykGXDao)_**

几个核心比较项

```yaml
- 抗封锁能力：基于协议伪装程度及对抗主动探测的能力（如TROJAN模拟HTTPS，Hysteria2伪装HTTP/3）。
- 拥塞控制：Brutal通过固定速率绕过TCP降速逻辑，显著提升劣质线路速度。
- 性能特点：VLESS因去加密环节提升吞吐；Hysteria2通过端口跳跃规避UDP QoS限制。
```

1、是否需要域名（还是“偷域名”）？

```yaml
- 【伪装域名】怎么选择？
# 要求：
#目标网站最低标准：国外网站，支持 TLSv1.3 与 H2，域名非跳转用（主域名可能被用于跳转到 www）
#加分项：IP 相近（更像，且延迟低），Server Hello 后的握手消息一起加密（如 dl.google.com），有 OCSP Stapling
#配置加分项：禁回国流量，TCP/80、UDP/443 也转发（REALITY 对外表现即为端口转发，目标 IP 冷门或许更好）
#
#没有屏蔽的大厂域名也可以，比如 www.apple.com, www.microsoft.com , www.cloudflare.com , www.samsung.com
#
#OCSP Stapling支持检查：
#http://web.chacuo.net/netocspstapling
#
#进入这个域名选择网站
#https://bgp.tools/
```

### 线路

- 【线路】御三家各自的优化线路分别是啥？

## singbox运行机制

### 关键配置项

:::tip

核心在于 DNS和route

:::

### singbox配置

```yaml
# [sing-box配置詳解 | 客户端服务器端配置 | 自行配置 ](https://www.youtube.com/watch?v=Mt3T2P9kybM)
# [sing-box 新手入门教程，使用配置、订阅转换方法攻略](https://blog.dun.im/anonymous/sing-box-dns-proxies-routes-rules-configuration-subscription-conversion-basic-tutorial.html)
- 【】singbox的config有哪些配置项？最新的4个key? (DNS, route, inbounds, outbounds)

- 【inbounds】sing-box 的 inbounds type 能否按「系统代理入口 / 透明接管入口(redirect/tproxy) / TUN 虚拟网卡入口 / 协议服务端入口」来归类？请按分类列出各 type，并解释每类适用平台/典型场景与限制点。
# 【inbounds】type 分组速查（按“流量怎么进来/你扮演什么角色”）
# inbounds:
#   A_system_proxy:     # 应用显式连到本机代理端口（最常见）
#     - mixed: "一个端口同时提供 SOCKS4/4a/5 + HTTP 代理"
#     - socks: "SOCKS 代理服务器入站"
#     - http: "HTTP 代理服务器入站"
#
#   B_transparent:      # 透明接管（依赖系统/防火墙把流量“转进来”）
#     - redirect: "透明重定向入站（仅 Linux/macOS）"
#     - tproxy: "TPROXY 透明入站（仅 Linux）"
#
#   C_virtual_interface:# 虚拟网卡接管（全局代理常用）
#     - tun: "TUN 虚拟网卡入站（系统级接管 IP 包）"
#
#   D_protocol_server:  # 把 sing-box 当“服务端”，给别的客户端连进来
#     - shadowsocks: "Shadowsocks 服务端入站"
#     - vmess: "VMess 服务端入站"
#     - trojan: "Trojan 服务端入站"
#     - vless: "VLESS 服务端入站"
#     - shadowtls: "ShadowTLS 服务端入站"
#     - anytls: "AnyTLS 服务端入站"
#     - hysteria: "Hysteria 服务端入站"
#     - hysteria2: "Hysteria2 服务端入站"
#     - tuic: "TUIC 服务端入站"
#     - naive: "NaiveProxy 服务端入站"
#
#   E_special:
#     - direct: "隧道服务器入站（可把收到的连接转发到指定目标地址/端口）"

- 【outbounds】sing-box 的 outbounds type 能否按「代理协议型 / 策略组型（selector, urltest） / 本地处理型（direct, block, dns））」三类来理解？请按这三类分别列出目前支持的 type 清单，并用一句话说明每个 type 的作用与典型使用场景。
# 【outbounds】type 三类速查（按官方当前 type 列表）
# outbounds:
#   1_proxy_protocol:   # 真正“连上游/远端”的协议（每个都是一个节点）
#     - socks: "连接到 SOCKS 上游代理"
#     - http: "连接到 HTTP 上游代理"
#     - shadowsocks: "Shadowsocks 客户端出站"
#     - vmess: "VMess 客户端出站"
#     - trojan: "Trojan 客户端出站"
#     - vless: "VLESS 客户端出站"
#     - shadowtls: "ShadowTLS 客户端出站（常与其他协议组合）"
#     - anytls: "AnyTLS 客户端出站"
#     - hysteria: "Hysteria 客户端出站（QUIC）"
#     - hysteria2: "Hysteria2 客户端出站（QUIC）"
#     - tuic: "TUIC 客户端出站（QUIC）"
#     - naive: "NaiveProxy 客户端出站"
#     - tor: "通过 Tor 网络出站"
#     - ssh: "通过 SSH 隧道出站"
#     - wireguard: "WireGuard 出站（旧 outbound；更推荐用 endpoint/wireguard）"
#
#   2_policy_group:     # 策略组/组合（自己不是协议节点，引用其他 outbounds 的 tag）
#     - selector: "手动选择一个子 outbound（目前主要通过 Clash API 控制）"
#     - urltest: "对一组子 outbound 做 URL/延迟测试并自动择优"
#
#   3_local_actions:    # 本地处理（不属于代理协议）
#     - direct: "直连目标地址（不走代理封装）"
#     - block: "阻断/拒绝连接"
#     - dns: "内部 DNS 服务器出站（无真实出站连接；已 deprecated，后续版本将移除）"

# A. 代理协议层（应用层/会话层的“代理隧道”）

# VLESS / Trojan / Shadowsocks / VMess / Hysteria2 / TUIC

# 它们负责：认证、封装你的 TCP/UDP 流量、（可选）多路复用等
# 并且通常“跑在某个传输之上”。“协议”和“传输方式”是两层东西。

# B. 传输层

# TCP（典型：WS/gRPC/HTTP2 都是跑在 TCP/TLS 上）

# UDP/QUIC（典型：Hysteria2、TUIC 基于 QUIC）

# C. 安全/伪装层（常被混称“TLS/Reality/XTLS/ShadowTLS”这一类）

# TLS：通用加密与握手外观

# REALITY：在 Xray 里是“替代 TLS 的安全层/仿真层”

# ShadowTLS：更像“外层伪装/承载”思路（通常叠在别的代理之上）

# D. VPN 隧道层（L3）

# WireGuard：直接承载 IP 包，创建虚拟网卡/路由语义，属于“真正的 VPN 隧道协议”

- 【outbounds】是否outbounds中不同 type 对应的字段不同？有哪些是必填字段？ # 不同type的对应字段确实不同。必填字段基本上就是 server、server_port、password 这三个

- 【dns】
- 【route】

- "***【detour配置链式代理】***" # https://linux.do/t/topic/785811

- 【】怎么判断配置好的singbox server的某个协议，是否真的生效了？
# • 你抓包是在本机做的，所以当然看不到“入站到服务器的包”。关键是要在
#142.171.154.61 服务器上抓包，才能证明你的公网 IP 是否到达服务器。
#
#请在目标机上（能登录的那台）执行下面步骤：
#
#1. 在目标机开抓包
#
#sudo tcpdump -ni any host 43.239.95.17 and port 22
#
#2. 你本机再连一次：
#
#ssh luck@142.171.154.61
#
#- 如果目标机 完全没有包，说明问题在 云厂商安全组/上游防火墙/运营商，不是本
#  机或 sshd。
#- 如果目标机能看到 SYN 但 sshd 日志没有记录，说明被 目标机本地防火墙 丢了
#  （nftables/iptables/Fail2ban 规则）。
#
#你这边的现象已经很像“上游丢包/拦截”：
#
#- 本机 ssh 连接建立后立刻被断开
#- sshd 日志中没有你的 IP
#- 说明 sshd 根本没机会处理
#
#补充排查（在目标机上）：
#
#sudo nft list ruleset | rg -n "22|ssh|drop|reject|43.239.95.17"
#sudo iptables -S | rg -n "22|ssh|DROP|REJECT|43.239.95.17"
#sudo fail2ban-client status 2>/dev/null
#sudo fail2ban-client status sshd 2>/dev/null
#
#如果确定是上游（云厂商/机房）拦了你的 IP：
#
#- 方案 1：临时改 SSH 端口（比如 2222）
#- 方案 2：用 WireGuard/跳板
#- 方案 3：在云厂商面板里白名单你的公网 IP
#
#你先在 目标机 抓包试一下，把结果贴出来，我再精确判断到底是哪一层挡掉的
```

## 主流相关工具

### **_zashboard_**

### ~~sub-store~~

```yaml
- url: https://github.com/sub-store-org/Sub-Store
# sub-store 的 why （也就是为啥需要配置 ss）
# 核心在于两点：大量节点、节点转换
# 前者指的是 “我觉得, 如果节点很多(比如到处搜集免费节点的人, 节点总数有可能成千上万), 那么这个测速+筛选的工作不应该由翻墙客户端来做, 应该由一个单独的实体来做。我找了一圈信息, 最终决定用 Sub-Store 完成这个任务.” 我之前想要做节点打野，所以也就需要 ss，需要把多个订阅URL做聚合，并支持 脚本操作/过滤、节点排序/去重、区域过滤、协议过滤、正则过滤/排序/删除/命名 之类的pipeline操作，最终转换成符合需求的脚本。
# 后者，如果节点不多的话，就不需要 ss 了吗？也并非如此，这里还有一种情况，就是有多个使用场景，比如说 “这就造成了一个问题，你很可能准备了多套配置模板，用于不同的终端（他们之间主要是inbounds字段不同），如Linux、windows、iOS，因此当你修改自定义规则的时候，需要同时修改多套json。依赖sub-store，可以很容易解决这个问题，你只需要在sub-store中存储一个名为“custom_rules.json”的文件，内容格式如下：”
# 即使只有一个节点，但是最终client不同，那就需要用ss去生成符合各client需求的配置（注意这点如果用nix也可以处理，也就是在nix里处理 inbounds，但是这个终究只能在nix里使用，如果是ios之类的，就无法使用了）

# 以上这个认知有问题吗？
# 没啥问题，但是这个顺序就说明，没抓到ss的核心能力。ss的核心在于“订阅转换”。
# **“大量节点”本身不是 Sub-Store 的核心能力**；它只是把需求放大后更痛的场景。真正的核心能力是把订阅处理抽象成一个**中间层流水线**：**parse → process → produce**，把“解析/过滤/改名/排序/生成目标格式”从客户端剥离出来，集中处理。
# 1. **把订阅处理从客户端剥离出来，集中成可编程流水线**（不看节点多少）。
# 2. **一个真源，多端多格式输出**（跨客户端/跨终端维护成本直接降维）。
# 3. **自动化分发/同步/可迁移**（订阅作为资产管理，而不是散落在各客户端里）。
```

### 机器

- https://github.com/oneclickvirt/ecs
- https://github.com/xykt/IPQuality
- https://github.com/xykt/NetQuality

## 总结
