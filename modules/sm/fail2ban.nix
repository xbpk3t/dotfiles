# sm 轨 fail2ban（纯 nix，不引入 ansible 装服务——bootstrap 只做窄门）。
# 上游 system-manager 未适配 services.fail2ban（仅 nginx/acme/meta），故按
# nixpkgs services.fail2ban 模块的等效结构在 sm 能力面重写。
#
# ⚠️ 关键教训（对抗式审查得出，避免再踩）：
#   1. 不要加 ExecStartPost "fail2ban-client -x start"——nixpkgs shipped 的
#      fail2ban.service 和 NixOS 模块都没有这行。它让客户端在启动时连 XML-RPC
#      socket，会撞上 fail2ban 的潜伏 bug（vendored asyncore.accept() 在
#      EWOULDBLOCK/ECONNABORTED 时返回 None，handle_accept 不解包防护，Python 3.12+
#      走 compat/asyncore 后更容易触发）→ 启动/重启崩溃。去掉它就干净启动。
#   2. 不需要给 fail2ban 打补丁：干净启动（无 ExecStartPost 客户端连接）实测正常，
#      与 NixOS 行为一致。版本 1.1.1/master 同样未修这个 bug，但正常路径不触发。
#   3. Type=simple（shipped unit 就是 simple，不是 forking——forking + 前台会卡 activating）。
#
# 这是 sm-vps 基线能力（安全硬化必需），不做配置化开关。
{ pkgs, ... }:
{
  _file = ./fail2ban.nix;

  environment.systemPackages = [ pkgs.fail2ban ];

  # /etc/fail2ban base → nix store 包配置。d 先建父目录，L+ 强制 symlink。
  # 注意与 environment.etc 的 jail.d 覆盖共存（不同子路径，无冲突）。
  systemd.tmpfiles.rules = [
    "d /etc/fail2ban 0755 root root -"
    "L+ /etc/fail2ban/fail2ban.conf - - - - ${pkgs.fail2ban}/etc/fail2ban/fail2ban.conf"
    "L+ /etc/fail2ban/jail.conf - - - - ${pkgs.fail2ban}/etc/fail2ban/jail.conf"
    "L+ /etc/fail2ban/paths-common.conf - - - - ${pkgs.fail2ban}/etc/fail2ban/paths-common.conf"
    # ⚠️ paths-debian.conf 必须存在：jail.conf 的 [INCLUDES] before = paths-debian.conf，
    # 它再 include paths-common.conf（定义 sshd_log/sshd_backend）。缺它 → 插值失败启动崩。
    "L+ /etc/fail2ban/paths-debian.conf - - - - ${pkgs.fail2ban}/etc/fail2ban/paths-debian.conf"
    "L+ /etc/fail2ban/action.d - - - - ${pkgs.fail2ban}/etc/fail2ban/action.d"
    "L+ /etc/fail2ban/filter.d - - - - ${pkgs.fail2ban}/etc/fail2ban/filter.d"
  ];

  # daemon 设置覆盖（对齐 nixos 轨 services.fail2ban.daemonSettings）：
  #   - logtarget=SYSLOG：unit 有 ProtectSystem=strict（/var 只读），不能写 /var/log/fail2ban.log；
  #     走 journald（journalctl -u fail2ban）。
  #   - socket/pidfile 用 /run/fail2ban（RuntimeDirectory 提供，可写）。
  #   - dbfile 放 /var/lib/fail2ban（StateDirectory 提供，unit 加了 StateDirectory）。
  environment.etc."fail2ban/fail2ban.local".text = ''
    [Definition]
    logtarget = SYSLOG
    socket = /run/fail2ban/fail2ban.sock
    pidfile = /run/fail2ban/fail2ban.pid
    dbfile = /var/lib/fail2ban/fail2ban.sqlite3
  '';

  # sshd jail。backend=auto：/var/log/auth.log 存在（rsyslog）走文件，否则 journald。
  #
  # ⚠️ mode=aggressive 是必须的（实测）：这台 sshd 密码认证已关（ansible P4 + sm sshd drop-in），
  # 失败认证不产 "Failed password/publickey" 行，而是以
  #   "Timeout before authentication for connection from <IP>" / "drop connection"
  #   / "Connection closed by authenticating user <IP> [preauth]"
  # 形式进 auth.log（扫描器正是这种，实测 30+ 次/10min）。默认 normal mode 匹配不到 → 永不 ban。
  # aggressive mode 才匹配这些 preauth 断开/超时模式。
  # maxretry=10：扫描器每 10min 命中 30+ 次照样秒 ban；但把我方（公网动态 IP）在扫描器
  # 洪泛期间的 SSH 瞬断误计排除在自锁半径外（实测 30min 我方仅 2 次，阈值 10 安全）。
  # ignoreip 加 tailnet CGNAT 段（100.64.0.0/10）：tailnet 通道访问不被误 ban（兜底逃生口）。
  environment.etc."fail2ban/jail.d/00-sm.conf".text = ''
    [DEFAULT]
    bantime = 1h
    ignoreip = 127.0.0.1/8 ::1 100.64.0.0/10

    [sshd]
    enabled = true
    maxretry = 10
    backend = auto
    mode = aggressive
  '';

  # 参照 nixpkgs shipped fail2ban.service（Type=simple，无 ExecStartPost）。
  # 注意：不要加 ExecStartPost client 连接（见文件头教训）。
  systemd.services.fail2ban = {
    enable = true;
    description = "fail2ban: ban IPs after repeated failed logins";
    wantedBy = [ "system-manager.target" ];
    after = [ "network.target" ];
    path = [ pkgs.fail2ban ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.fail2ban}/bin/fail2ban-server -c /etc/fail2ban -xf start";
      ExecStop = "${pkgs.fail2ban}/bin/fail2ban-client -c /etc/fail2ban stop";
      RuntimeDirectory = "fail2ban";
      RuntimeDirectoryMode = "0750";
      # dbfile 放 /var/lib/fail2ban（ProtectSystem=strict 下 systemd 会为该目录加读写挂载）
      StateDirectory = "fail2ban";
      StateDirectoryMode = "0750";
      Restart = "on-failure";
      RestartSec = "10s";
      # 与 nixpkgs 模块一致的最小加固（fail2ban 需要 NET_ADMIN/NET_RAW 写防火墙）
      CapabilityBoundingSet = [ "CAP_AUDIT_READ" "CAP_DAC_READ_SEARCH" "CAP_NET_ADMIN" "CAP_NET_RAW" ];
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectHostname = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
    };
  };
}
