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
  networking.firewall.enable = lib.mkDefault true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = mkMerge [
      {
        # 禁止 root 密码登录，仅允许基于密钥的部署
        PermitRootLogin = "prohibit-password";
        # 禁用密码认证，强制公钥
        PasswordAuthentication = false;

        # 连接优化与基础加固（通用基线）
        UseDns = false; # 关闭反向 DNS，加速握手
        Ciphers = [
          "aes256-ctr"
          "chacha20-poly1305@openssh.com"
        ];
        # 让 TCP 层发送 keepalive
        TCPKeepAlive = true;
        # 默认关闭转发，按角色再放开
        AllowTcpForwarding = false;
        # 禁止反向端口绑定到 0.0.0.0
        GatewayPorts = "no";
        # 默认关闭隧道，按角色再放开
        PermitTunnel = false;
        # 启用公钥认证
        PubkeyAuthentication = true;
      }

      (mkIf isDesktop {
        # 桌面/跳板：开放便捷功能、拉长心跳
        X11Forwarding = true;
        AllowTcpForwarding = true;
        # 允许隧道
        PermitTunnel = true;
        # 启用压缩，降低交互延迟
        Compression = true;
        ClientAliveInterval = 3000;
        ClientAliveCountMax = 100;
      })

      (mkIf isServer {
        # 禁用键盘交互（含 OTP/PAM），减少暴力破解面
        KbdInteractiveAuthentication = false;
        # VPS 不提供图形，关闭 X11 转发
        X11Forwarding = false;
        # 禁止代理转发，避免泄露本地凭据
        AllowAgentForwarding = false;
        # 更快探测断链，释放卡住的会话
        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;
        # 再次明确禁用 DNS 反查，保持一致
        UseDns = false;
        # 禁止 TCP 转发，降低横向移动风险
        AllowTcpForwarding = false;
        PermitTunnel = false;
      })
    ];
  };

  # Add terminfo database of all known terminals to the system profile.
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/config/terminfo.nix
  # [2025-11-28] 设置为false，因为 termbench-pro 在rebuild时报错。
  # 绝大多数常用终端（xterm, foot, kitty, wezterm, tmux 等）在 NixOS 主包里已经自带 terminfo，使用它们时不会有任何变化。只有当你运行“系统上没有安装、但 SSH 到别的机器时又需要正确 terminfo”的冷门终端名（例如 contour、某些古老/自编译终端）时，远端才可能因为 TERM 无法匹配而退回到 vt100 之类的兼容模式。对日常开发和常见终端来说几乎不会遇到。
  environment.enableAllTerminfo = false;
}
