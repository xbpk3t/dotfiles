{
  config,
  lib,
  ...
}: let
  inherit (lib) mkMerge mkIf;
  isDesktop = config.modules.roles.isDesktop;
  isServer = config.modules.roles.isServer;
in {
  # Or disable the firewall altogether.
  # 默认开启（如果workstation等场景不需要时，则在hosts中overrides该配置）
  # 服务器建议开启防火墙，桌面可以依赖 NetworkManager 自动规则
  # [2025-12-19]
  networking.firewall.enable = lib.mkDefault false;

  # Enable the OpenSSH daemon.
  # https://mynixos.com/nixpkgs/options/services.openssh
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = mkMerge [
      {
        # 禁止 root 密码登录，仅允许基于密钥的部署
        PermitRootLogin = "prohibit-password";
        # 禁用密码认证，强制公钥
        PasswordAuthentication = false;

        #  PermitRootLogin = "yes";
        #  PasswordAuthentication = true;

        # 提高日志粒度便于审计，记录认证阶段详情但不过度冗长
        LogLevel = "VERBOSE";
        # 将 SSH 日志放入 AUTHPRIV，避免混入系统日志并限制读取范围
        SyslogFacility = "AUTHPRIV";

        # 抗暴力破解：限制尝试次数、握手宽限时间与并发启动连接
        # 3 次失败即断开，降低弱口令穷举窗口
        MaxAuthTries = 3;
        # 30 秒内未完成认证则中断
        LoginGraceTime = "30s";
        # 10 并发后按 30% 概率丢弃，100 为硬上限
        MaxStartups = "10:30:100";
        # 每连接最大会话数，避免过多 session 占用资源
        MaxSessions = 10;

        # 连接优化与基础加固（通用基线）
        # 关闭反向 DNS，加速握手
        # VerifyReverseMapping 配置项（反向解析 + 校验是否能映射回同一IP）已经deprecated，且整合到 UseDns 里（UseDNS 会“lookup remote host name，并检查反查得到的主机名再解析回来的 IP 是否还是同一个 IP”）。
        # UseDns = false; 就已经是“跳过反向 DNS（以及那套映射校验）”
        UseDns = false;
        Ciphers = [
          "aes256-ctr"
          "chacha20-poly1305@openssh.com"
        ];
        # 让 TCP 层发送 keepalive
        TCPKeepAlive = true;
        # 默认关闭转发，按角色再放开
        # 禁止 TCP 转发，降低横向移动风险
        # 不需要Desktop作为跳板机，所以也同样设置为false。那么就抽到common里。
        # [2025-12-24] 用来做 remote dev，需要开启该配置项（需要 remote 端口转发）
        AllowTcpForwarding = "yes";

        # 禁止反向端口绑定到 0.0.0.0
        GatewayPorts = "no";
        # 默认关闭隧道，按角色再放开
        # PermitTunnel 是 sshd_config 的开关，用来允许登录用户通过 SSH 建立 层 2/层 3 的点对点隧道。具体行为：
        #
        #- PermitTunnel yes：允许开 tun(3) 或 tap(4) 设备，客户端可用 ssh -w local_tun:remote_tun user@host 建立 IP 隧道；也可用 tap 做以太网桥接。
        #- PermitTunnel point-to-point：只允许 tun（IP 点对点）。
        #- PermitTunnel ethernet：只允许 tap（以太网帧）。
        #- 默认 no：禁用隧道，ssh -w 直接失败。
        #
        #用途/价值
        #
        #- 临时、纯 SSH 的“内网穿透”或站点到站点小隧道，不用再部署 OpenVPN/WireGuard。
        #- 做跳板时，把特定流量（如管理网段）经 SSH 隧道走，加密+认证一并解决。
        #- 可配合 ForceCommand、PermitOpen、防火墙，把隧道用途锁定在小范围。
        #
        #风险/代价
        #
        #- 隧道可绕过本地防火墙/出口策略，扩大横向移动面。
        #- 需要 tun/tap 内核能力；若系统禁用或容器缺少 CAP_NET_ADMIN，会失败但无害。
        #- 运营复杂：路由/地址分配/MTU 需要手工或脚本配置。
        #
        #启用决策建议
        #
        #- 不需要 SSH 隧道（已有 VPN/WireGuard，或只用端口转发即可）→ 保持默认 PermitTunnel no，面减少攻击面。
        #- 需要用 SSH 临时做点对点隧道，并且信任有 shell 的用户 → 可设为 point-to-point（常用最安全的子集）。
        #- 需要 L2 桥接/以太网封装 → 设为 ethernet，但要额外注意广播面和环路。
        #- 不要全局开放给所有用户：最好配合 Match User/Group 仅对白名单账号开放，并配路由/防火墙限制隧道能访问的网段。
        #
        #
        #不是自动“打洞”。PermitTunnel 只是允许客户端用 ssh -w <tun>:<tun> 主动要求 sshd 创 建 tun/tap设备，再由你手动配置 IP/路由。不开这个，ssh 不会自己做内网穿透；开了也不会自动连通，除非有人用 ssh -w 并有 CAP_NET_ADMIN 权限。
        #
        #你已有 NetBird（WireGuard 叠加控制面）做内网互连，更安全、自动化且可控。对桌面机：
        #
        #- 没特定需求用 SSH 做 L2/L3 隧道 → 建议 PermitTunnel no。
        #- 只在极少数场景需要临时 tun 隧道，可设 point-to-point 并用 Match User 限制账号，否则保持 no。
        PermitTunnel = false;
        # 启用公钥认证
        PubkeyAuthentication = true;

        # 禁用压缩
        # 服务器端允许/默认开启压缩。好处是慢链路（移动/跨国）交互更流畅；坏处是 CPU 开销大、已被加密后压缩收益有限，局域网几乎无意义。
        # 之所以禁用，是因为默认所有机器都配置了Netbird Client，默认通过 LAN IP 进行访问。
        ## NetBird 已经把流量封装在 WireGuard 里，端到端加密且通常跑在可靠、相对低延迟的链路（LAN 或近似 LAN 的 overlay）。在这种场景：
        ##  - 压缩收益很低：数据已加密，压缩率差，而且多一层 CPU 开销。
        ##  - 可能反而伤性能：对端 CPU/内存增加，延迟上升一点点。
        Compression = false;
        # 探测断链，释放卡住的会话
        # ClientAliveInterval + ClientAliveCountMax: 服务端心跳（server→client）。超时后断开连接，防僵尸会话，同时也能穿 NAT 防掉线。Effective timeout = Interval × CountMax。
        # 直接设置统一的timeout
        # 120 * 20 = 2400s -> 40min
        ClientAliveInterval = 120;
        ClientAliveCountMax = 20;

        # 避免 Unix 域转发残留旧 socket，自动覆盖同名文件
        StreamLocalBindUnlink = true;

        # 主动重协商 key，限制长期会话的密文暴露面（1GiB 或 1h 触发）
        RekeyLimit = "1G 1h";
      }

      (mkIf isDesktop {
        # 桌面/跳板：开放便捷功能、拉长心跳
        X11Forwarding = true;
      })

      (mkIf isServer {
        # VPS 不提供图形，关闭 X11 转发
        X11Forwarding = false;

        # 服务器场景：保持最小信任域，关闭 GSSAPI/SASL 等域认证通道
        # 禁用键盘交互（含 OTP/PAM），减少暴力破解面
        KbdInteractiveAuthentication = false;

        # 禁止代理转发，避免泄露本地凭据
        AllowAgentForwarding = false;
      })
    ];
  };

  # Add terminfo database of all known terminals to the system profile.
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/config/terminfo.nix
  # [2025-11-28] 设置为false，因为 termbench-pro 在rebuild时报错。
  # 绝大多数常用终端（xterm, foot, kitty, wezterm, tmux 等）在 NixOS 主包里已经自带 terminfo，使用它们时不会有任何变化。只有当你运行“系统上没有安装、但 SSH 到别的机器时又需要正确 terminfo”的冷门终端名（例如 contour、某些古老/自编译终端）时，远端才可能因为 TERM 无法匹配而退回到 vt100 之类的兼容模式。对日常开发和常见终端来说几乎不会遇到。
  # [2025-12-17] 还是需要启用该配置。mac上用ghostty通过ssh到 nixos-desktop，如果未启用该配置，就无法使用Ctrl+u等快捷操作。甚至无法删除已输入命令。
  environment.enableAllTerminfo = true;
}
