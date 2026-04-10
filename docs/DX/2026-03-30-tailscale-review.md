---
title: wireguard-VPN
date: 2026-03-30
isOriginal: true
---


netbird 要不就全套自建，要不就直接使用官方服务，不支持类似 tailscale 这种只自建 relay server (并加入回官方控制面 DerpMap)

NAT分为多种类型：

- NAT映射行为
- firewall

但对于NAT穿透，只需要看NAT

1、所有内网穿透的流程都类似 Auth ->

2、内网穿透的核心是其中哪步（其他流程都是辅助该操作的）？

STUN （端点发现） + signal (协商/交换 候选endpoint 并驱动打点)




### tailscale/netbird

:::tip

作为 host=nixos-vps，所有VPS就既是 tailscale 的 client (=node) 和 Derp Relay Server

:::

需要注意的是，对于 client来说，部署是很简单的。

但是对于 Derp 来说，要求必须TLS证书，所以使用ACME的DNS-01签发。这里的问题在于，URL的 subdomain 需要动态生成（不可能多台VPS去抢注同一个域名，如果是同一个固定域名，那么只有第一个VPS可以抢注成功，后面的都会失败，也不符合我们的需求）。

这里有两台路线，

一条是直接使用为colmena写的targets metadata作为hosts数据源，让我们可以动态生成 config.networking.hostName。但是这里的问题在于，如果使用colmena targets作为数据源，有两个需求无法满足：1、我希望不只是 hosts/nixos-vps，其他hosts也可以直接实现类似效果。2、不只是colmena，其他部署方式也可以动态生成hostName。总之因为实现复杂性，所以放弃该方案。

另一个方案则简单得多，维护两套 hosts metadata确实麻烦，但是从实现来说，却容易得多。直接复用了之前在 vars/networking.nix 里给 singbox 维护的 vpsNodes作为数据源。然后添加了 lib/node-id.nix 用来通过IP匹配node，又在colmena里实现了动态生成 hostName（而非直接修改 hosts/nixos-vps 的 hostName，注意这点有天壤之别）












---


```yaml
    - topic: 异地组网工具
      why:
        - 【解决无公网IP痛点】在运营商不分配公网IP或企业防火墙严格的环境下，实现跨地域设备的安全互通
        - 【替代传统VPN】避免公网IP依赖和端口映射复杂性，提升连接稳定性与速度

        - 【2025-08-01】移除“【技术选型】组网工具”【tailscale (headscale)】、【zerotier + moon】、【netbird】。虚拟组网工具归根到底是要看打洞能力吧，不在于其他东西。
        - 1、【server位置】这里需要注意他这个server只在打洞那一下有用（***需要注意server位置会影响 节点注册和打洞协商 的速度***，延迟越低，打洞成功率就越高），如果打洞成功了，VLAN里的所有node都直接P2P了，不需要再走server。但是如果打洞没成功，就会走中继模式，也就是server作为兜底。所以可以得出结论：server尽量在国内，以降低延迟，保证打洞成功。
        - 2、【打洞协议】抛开上面说的server位置，真正需要注意的是三套方案的打洞协议不同，都说Netbird最好用，为啥呢？具体来说，其中Tailscale用的是STUN + DERP（TCP中继）。ZeroTier用的是传统STUN + UDP中继。NetBird用的是WebRTC ICE框架 + STUN/TURN。

        - 所以NAT穿透力、吞吐量的排序如下：NetBird > Tailscale > ZeroTier。另外配置NetBird也比Tailscale更简单。可以用netbird status是否返回p2p来判断是否打洞成功。

        - 【技术选型】只考虑自建server，到底用tailscale还是netbird?
        # 1、客户端易用性（tailscale更优）：毫无疑问tailscale生态更优，client覆盖了win/mac/linux/ios/android/NAS/容器全生态。并且UI和手感也更好。
        # 2、自建、架构复杂度（tailscale更简单，Netbird更“企业级”）
        ## “headscale 基本的设备管理、ACL、子网路由、出口节点都能满足个人/小团队。”
        ## “NetBird 自建：官方就把自建当一等公民：提供 Management Service + Dashboard UI + Signal + Coturn + IdP 集成 的完整方案。” 所以部署时，会比headscale麻烦（）
        # 3、性能（Netbird更优）：二者都是基于WireGuard的 overlay mesh网络，也都是“先尝试打洞，打洞失败走中继relay（）”。但是Netbird走内核态WireGuard（在高带宽场景理论更占优势），而Tailscale则是用户态WireGuard（理论上够用，但...）
        # 4、功能（各有千秋）：
        ## Tailscale 生态：Taildrop、Funnel、与很多 SaaS/身份系统集成，但这些高级功能大多依赖官方云控制平面，自建 Headscale 时部分功能不可用。
        ## NetBird：从设计上就强调 self-host + 企业级场景，提供原生的 Web Dashboard, 访问策略ACL, SSO, Terraform provider等等。

        # 总结：在server端来说，netbird更好，从client的易用性还说，tailscale更好。“个人就用tailscale，企业用netbird”（Netbird是Web 后台 + 用户/组/ACL/SSO 基本开箱即用，适合多人协作。而Headscale没有WebUI，但也更简洁，该有的功能也都有）
        # 想了一下最终决定用netbird
        # 因为tailscale的优势在于生态（覆盖 win/mac/linux/ios/android/NAS/容器 等全平台），但是更多是PaaS方向，而非自建。太多功能仅限官方服务，如果自建就无法使用了。而netbird除了性能更好以外，本身也更适合自建。

      what:
        - 【核心功能】通过虚拟局域网（VLAN）连接分散设备，支持P2P直连或中继转发
        - 【技术原理】基于WebRTC ICE框架，结合STUN/TURN协议实现NAT穿透（穿透能力：NetBird > Tailscale > ZeroTier）
      ww:
        - 【server部署在哪】我目前几台设备：两台VPS(LA大宽带机器（1.5T），HK高配置小宽带（10MB）)、两台workstation机器、一套homelab（高配置16C128GB内存）我应该把 tailscale server 部署在哪台机器上？
        # 具体决策如下：
        # 1、首先当然不考虑workstation（因为这些机器并非7x24在线），也不考虑homelab（因为需要科学上网才能访问外网，一旦代理挂了，headscale控制端就掉了）。总之这些机器本身对外IP/出口都不稳定，不考虑。
        # 2、只考虑VPS，那是选择LA的大带宽机器，还是HK的低延迟机器？结论是选择后者，因为对异地组网来说，控制平面+DERP都很轻量，不吃多少带宽，我的大部分设备都在国内，连接HK延迟比LA要低很多，握手和打洞的成功率都更高。只要带宽不是特别离谱（5MB以下），一般都够用。
        # 拓展：进一步的，如果担心可能经常打洞失败，那就把Headscale放在HK，把DERP中继服务放在LA。

        - 【企业应用】分支互联、远程访问ERP/OA系统（需规避EDR告警，推荐星空组网）
        - 【家庭场景】访问家庭NAS、智能家居设备（需长期稳定连接）
      htu:
        - 【】为啥更推荐把tailscale做nix化，而非compose部署？ # 因为这类服务本身是infra的一部分（更有长期使用价值），所以更应该nix化，随机起停（而非compose这种本身有生命周期管理的第三方工具）

        - 【部署流程】服务端需靠近用户（如国内节点），降低协商延迟提升打洞成功率；检查连接状态：`netbird status`返回`p2p`表示直连成功
        - 【性能验证】测试带宽与丢包率（参考值：星空组网丢包率3%，Zerotier 8%）
      hti:
        - 【STUN】是啥？
        - 【TURN中继】是啥？ # TURN (Traversal Using Relays around NAT) 是 WebRTC标准里定义的一种NAT穿透中继协议。简单来说，当两台机器都处在严格NAT(比如 对称NAT)后面，STUN打洞（UDP hole punching）失败、无法直连时，就只能走Relay Server来转发流量。
        # 需要注意的是，（中继）机制是类似的，但是Netbird和Tailscale对其实现不同。Netbird使用Coturn（开源项目，最流行的TURN服务器实现，标准TURN协议），而Tailscale则是DERP（自研中继协议）

        - 【中继协议】TURN和DERP
        - 【自建私有DERP server】使用域名还是IP？
        - 【】怎么防止DERP被白嫖？

        - 【协议选择】工业场景需二层透传（如蒲公英支持PLC协议）；普通场景选WebRTC框架（穿透率更高）
      hto:
        - 【降低延迟】优先启用P2P模式（中继带宽损耗10-20%）；自建TURN服务器减少中继跳转
        - 【安全加固】启用WireGuard端到端加密；限制设备访问权限隔离敏感资源

    - topic: 优化异地组网latency
      ww:
      qs:
        - 我有异地组网的需求，你觉得需要把remote server的latency 压到多少，才能保证作为远程开发，以及其他高级需求，不卡顿？ 目标20ms以内，50ms以内可用
        - 延迟不只取决于网络距离，还受服务器位置、路由路径、带宽和协议影响
        # 地理位置：如果服务器在洲际间，基础延迟可能已达100ms以上（例如中美间ping值常在150-200ms）。建议选择就近的边缘服务器或CDN节点。
        # 协议优化：使用SSH over WireGuard、Tailscale或ZeroTier等工具，能比传统VPN降低20-50ms延迟。
        # 硬件与软件：确保服务器有足够的CPU/内存，避免瓶颈。工具如Coder或Gitpod强调直接连接以最小化延迟。
        # 测试方法：用ping或traceroute测量实际延迟，并模拟开发场景测试（e.g., 编辑大文件或运行终端命令）。

        - 【常见问题】latency高，有哪些常见问题？
        # 问题类型	        可能原因	                        影响范围
        # NAT 类型限制	    对称型 NAT 不支持直接穿透	      节点间无法直连，依赖中继
        # 防火墙/ACL阻止	    UDP/TCP 端口未开放或保活包被过滤  心跳丢失导致连接中断
        # STUN/TURN配置错误	未正确设置 STUN 服务器或         TURN 中继不可达	无法获取公网地址或建立中继通道
        # 网络路径不稳定	    公网链路丢包或延迟突变	          通信质量下降，触发重传或超时

      hto:
        - "***有哪些方法可以降低 tailscale 连接的latency? 这是一个开放问题，从有效性 desc排序，给我列出几项***"
# 下面按**“对 latency 的有效性（通常从高到低）”**给你列一些在 Tailscale 里最常见、最有效的办法。核心思路就一句话：**能直连就直连；不能直连就把“中转那一跳”放到离你更近的地方**。


## 1) 让连接从 DERP/relay 变成直连（Direct）

# **通常是降延迟最明显的一项**。Tailscale 会优先尝试直连；直连几乎总是更低延迟、更高性能。 ([Tailscale][1])

# 你要做的是提升“直连成功率”，常见抓手：

# - **确保两端都有可用的出站 UDP**（很多“高延迟”其实是被迫走中继）：`tailscale netcheck` 里 `UDP: true` 很关键。 ([Tailscale][2])
# - **改善 NAT/防火墙条件**：能的话给其中一端提供更“友好”的网络（公网 IP、较少限制的 NAT），必要时按文档建议开防火墙端口。 ([Tailscale][1])

# 怎么确认你现在是不是直连：

# - `tailscale status`：看对端是 `direct` 还是 `relay/peer-relay`。 ([Tailscale][3])
# - `tailscale ping <peer>`：会显示是否走了 DERP、延迟多少。 ([Tailscale][4])

# ---

# ## 2) 直连不行时，优先用 Peer Relay（同 Tailnet 的“自家中转”）

# 如果环境导致直连很难（典型：硬 NAT / 对称 NAT / 某些蜂窝网络），那**Peer Relay 往往比 DERP 更低延迟**，因为中转在你自己的基础设施里、更可控，也通常离你更近。 ([Tailscale][3])

# 适用场景：

# - 你有一台/几台位于“网络条件好、地理位置居中”的机器（云主机/办公室网关），愿意让它当中转点。

# ---

# ## 3) 如果你经常被迫走 DERP：让 DERP 更近（或自建 DERP / 调整 DERP map）

# 走 DERP 会多一跳，所以延迟更高是正常的；而且 DERP 还会做 QoS/限流来保证公平性。 ([Tailscale][4])

# 优化方向：

# - **先用 `tailscale netcheck` 看你“最近的 DERP”延迟**，确认是不是选到了不理想的区域。 ([Tailscale][5])
# - **定制 DERP map**：你可以在 tailnet policy 里自定义/禁用某些 DERP region（让客户端更倾向用更近的）。 ([Tailscale][5])
# - **少数情况下自建 DERP**：官方文档明确说大多数情况没必要、维护成本高，但如果你**频繁**走 DERP 且官方 DERP 对你确实不理想，自建可能能把“那一跳”放到更近的机房。 ([Tailscale][5])

# > 实务建议：如果你的目标是“稳定低延迟”，Tailscale 官方更倾向你优先考虑 **Peer Relay**，而不是自建 DERP。 ([Tailscale][5])

# ---

# ## 4) 避免不必要的“绕路”：能不用 Exit Node / Subnet Router 就不用；要用就放近一点

# 如果你把流量送去远端 Exit Node/子网路由器再出来，本质上就是多走了额外路径，延迟往往会上去（尤其跨地域）。官方性能最佳实践也把 exit node / subnet router 单独列为需要注意的模式。 ([Tailscale][1])

# 优化方法：

# - **把 Exit Node/路由器部署在离客户端更近的区域**
# - **让访问目标尽量就近出网**（例如访问公司内网就用公司边界，访问某云服务就把出口放到同区域）

# ---

# ## 5) 维护层面的“小幅优化”：升级系统/内核/客户端，减少退化情况

# 这类通常对“纯 RTT”提升没前面几项大，但能减少一些边缘退化（尤其当你设备当路由/出口、或系统网络栈较老时）。例如官方建议在 Linux 上用较新的内核版本以获得更好的性能特性。 ([Tailscale][1])

# ---

# ### 一套最快的排查/决策流程（很实用）

# 1. `tailscale status` 看是 `direct` 还是 `relay/peer-relay` ([Tailscale][3])
# 2. `tailscale ping <peer>` 看延迟、是否走 DERP ([Tailscale][4])
# 3. 两端各跑一次 `tailscale netcheck`：重点看 `UDP`、端口映射、以及最近 DERP 延迟 ([Tailscale][2])
# 4. 结论：

#    - 能直连 → 优先解决 NAT/UDP/防火墙，让它稳定直连
#    - 不能直连 → 上 Peer Relay
#    - 仍频繁 DERP 且 DERP 很远 → 再考虑 DERP map/自建 DERP

# ---

# 如果你愿意贴两端的（脱敏）输出：`tailscale status` + `tailscale ping 对端` + `tailscale netcheck`，我可以直接告诉你**你现在卡在第几类问题**，以及最可能的一两项“立竿见影”的改法。

# [1]: https://tailscale.com/kb/1320/performance-best-practices "Performance best practices · Tailscale Docs"
# [2]: https://tailscale.com/kb/1411/device-connectivity "Device connectivity · Tailscale Docs"
# [3]: https://tailscale.com/kb/1257/connection-types "Connection types · Tailscale Docs"
# [4]: https://tailscale.com/kb/1638/poor-performance-tailnet "Poor performance between tailnet devices · Tailscale Docs"
# [5]: https://tailscale.com/kb/1232/derp-servers "DERP servers · Tailscale Docs"

```


组网工具 + remote desktop 组合使用：组网工具负责优化网络（构建VPN），RD负责画面渲染、指令转发映射、音视频流


STUN, TURN


tun/tap veth pair

内网穿透 和 异地组网 是两码事

内网穿透： frp, 【ngrok】、【cft】、【easytier】

异地组网：【zerotier + moon】、【netbird】

混合工具：NPS, headscale

---

二者核心区别：
穿透                          组网工具
- NAT打洞能力   无打洞能力                       有
- 适用场景      临时暴露中转server              长期稳定跨网络设备互通







```yaml
      record:
        - date: 2024-03-02
          des: rustdesk其实也并没有之前看reddit上大家所说的那么快，尤其是不自己部署relay server的情况下，连接慢，还非常卡。支持远程唤醒（也就是在remote机器睡眠的情况下，晃动一下鼠标就能点亮显示器）。当然局域网下还是很快的，因为支持TCP-Tunneling嘛，直接内网打洞了。看来rustdesk还是得VPS自建才行，直接用官方提供的真不太行，很卡。

        - date: 2025-07-31
          des: 移除了“【技术选型】远程桌面”。这里也梳理一下相关工具。先说要求“2k 60帧不糊不卡就行”。那么排除【RDP（仅限win使用）】。再先排除掉【ToDesk（游戏版¥298/年，还只有最高2K144帧）】、【向日葵（游戏版¥225/年）】。再排除掉【TeamViewer】、【AnyDesk】、【GoToMyPC】这三个在国内没优化的。剩下的其实就两条路：【RustDesk】+国内VPS自建，或者用【PARSEC】、【网易UU远程（本身就是对标前者的，国内很顺滑）】这种两个方案。那怎么选也是显然的，毫无疑问能白嫖就白嫖，先选后者，等后者收费了再自建。另外，还需要说明为啥这种“穿透RD工具”相较传统RD工具更好用还更便宜？因为这类穿透RD实际上做了 异地组网（打洞）+RD，组网之后打洞成功，所以能实现P2P连接，就不需要服务器成本了。本身成本就低，所以收费就低。那为啥传统的这些RD工具又基于什么考虑没有做这个操作呢？归根到底还是场景问题，传统RD工具通常是企业办公场景，速度不重要，重在稳定。所以这类工具为了保证100%连通性，就默认全程中转，牺牲性能换稳定性。本质上来说是传统RD工具需要一个VPS作为中介来保证稳定性，简单来说就是弱网场景。但是如果你自己能够保证控制节点和被控节点都网络环境不错，那么用Parsec与网易UU这种工具是个更好的方案。 #
        - date: 2025-08-01
          des: 其实从RD协议（RDP、SPICE、RFB (VNC)、VDP、PCoIP、ICA/HDX），基本上就能得出各种RD工具的使用特点了。比如说 RDP因为只传输指令而非完整图像，客户端需本地渲染，因此带宽需求低。在低丢包网络中延迟较低（因指令传输量小），但高丢包网络可能因TCP重传导致延迟上升。而rustdesk使用RFB，就其实是server渲染好之后，再传给client，因此带宽需求高。基础延迟较高（需等待服务器渲染+图像编码传输），但网络波动时更稳定（因图像帧独立传输）。其实这里应该画个table对比一下各种RD协议，但是感觉也没啥必要了，这两天才刚刚删掉一堆之前整理的各种技术选型table，没啥意义。
        - date: 2025-10-13
          des: |
            昨晚在搞定netbird之后，在mac上用rustdesk+IP直连到NixOS，但是有报错，确定为bug。所以想看看是否还有其他类似远程桌面工具。Guacamole、xrdp、Remmina、NoMachine、MeshCentral。结合我的需求：linux原生（wayland支持）、内存开销、性能、响应速度，以及对于 P2P网络支持（内置NAT穿透，上面也说了我主要是通过 VLAN连接）、是否支持VLAN连接（也就是IP直连）。这里需要澄清一个之前不懂的细节，***NAT穿透和VLAN支持 是两码事*** 。
            另外还有两个问题：
            1、Remmina 相较 rustdesk 的优缺点？
            2、为啥不选择剩下几个？这几个有哪些劣势？


            - Remmina 优势: Remmina 在 NixOS 上原生支持 Wayland，无 RustDesk 的 bug（如 “Wayland requires higher version” 错误），GTK 集成无缝，内存占用低 (~80MB)，支持多协议（RDP/VNC/SSH），VLAN 直连 Netbird IP 简单（延迟 ~15ms）。适合 Linux 环境，配置零复杂。
            - RustDesk 优势: RustDesk 提供内置 NAT 穿透（90%+ 成功率），无需手动端口转发，适合公网场景；VLAN 下 P2P 连接延迟极低 (~10ms)，UI 现代化（类似 TeamViewer），跨平台体验统一（Mac/Linux/移动端），支持文件传输/聊天，易用性更高。

            Apache Guacamole 需复杂服务器配置（Docker/Tomcat），Web 架构导致 VLAN 延迟高 (~50ms)；xrdp 仅支持 RDP，无内置 NAT 穿透，公网需手动端口转发，配置麻烦；NoMachine 开源版功能受限（缺少高级压缩/插件），企业版非免费；MeshCentral 依赖 Node.js，内存占用高 (~300MB)，WebSocket 架构在 VLAN 下 overhead 大，设置复杂。相比之下，Remmina + xrdp 组合在 Wayland 和 VLAN 场景中更稳定简单，适合你的需求。


```



```yaml
        - date: 2025-08-01
          des: |
            移除“【技术选型】穿透工具”【frp】、【ngrok】、【cft】、【easytier】。这几个工具之间其实没有替代关系，确实各自都有自己的使用场景。具体是用哪个，可以用一下“4连问”找到匹配工具。是否为web服务（还是需要暴露TCP/UDP）？是否需要长期暴露？是否在用cloudflare？是否有公网VPS？如果是web服务且需要长期暴露且在cf，那就用Cloudflare Tunnel。如果只是暂时暴露，那用ngrok最方便（免费版session限8h）。如果需要长期暴露且有公网VPS（又或者需要暴露非Web协议（如SSH、数据库端口））那就用frp或者EasyTier。

            写到这里，我想起来我之前遇到的一个情况就很典型。我之前有次需要在第二天去外地演示一个项目，但是呢，需要RDB, CK乱七八糟服务加起来在test环境数据量差不多700GB，这个服务才能拉起来。那天已经11点半了才意识到这个问题。为了第二天演示正常，就只能赶紧把所有服务在我本地起了一套，把数据也migrate了一份到本地。就很累很疲惫。如果当时知道有cloudflare tunnel的话（之前只知道ngrok，但是ngrok有8h限制，也就没用），其实就不需要这么搞了是吗？另外，其实也可以直接用RD工具直接连接查看也可以，但是这个场景下肯定不如cft好用。

```
