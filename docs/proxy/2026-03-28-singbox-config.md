


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
