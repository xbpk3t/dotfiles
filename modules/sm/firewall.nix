# sm 轨入站防火墙（iptables rules，声明式）。
#
# 为什么 iptables 而非 nftables：
#   - 机器现状：INPUT 链由 iptables 管（fail2ban 用 iptables action：
#     banaction=iptables-multiport 插 f2b-sshd 链）；nftables 只被 tailscale
#     用（ts-input/ts-forward）。再开一套 nftables INPUT 会双套冲突。
#   - fail2ban 的 iptables-multiport 在 INPUT 上插 f2b-sshd 链（DROP 已 ban IP）。
#     这里把 f2b-sshd JUMP 放前面，让 fail2ban 的 DROP 先生效。
#
# 规则文件 /etc/iptables/sm-input.rules（iptables-restore 格式）：
#   - 放行：已建连、loopback、云盾链（YJ-FIREWALL-INPUT，腾讯云安全组）、
#     tailscale 接口、ICMP、22（ssh）、8443（sing-box）。
#   - f2b-sshd 链 JUMP（fail2ban 动态 ban，声明前先有）。
#   - 其余 DROP + LOG。
#
# 幂等：sm switch 时 iptables-restore 全量应用（--noflush 语义由 -n 承担）。
# 与 cloud-init 的 YJ-FIREWALL-INPUT 链共存（保留它，不覆盖）。
#
# 这是 sm-vps 基线能力（安全硬化必需），不做配置化开关。
{ pkgs, ... }:
{
  _file = ./firewall.nix;

  environment.etc."iptables/sm-input.rules".text = ''
    *filter
    :INPUT DROP [0:0]
    :FORWARD ACCEPT [0:0]
    :OUTPUT ACCEPT [0:0]
    :YJ-FIREWALL-INPUT - [0:0]
    :f2b-sshd - [0:0]
    # 已建连/回环/云盾
    -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    -A INPUT -i lo -j ACCEPT
    -A INPUT -j YJ-FIREWALL-INPUT
    -A INPUT -i tailscale0 -j ACCEPT
    -A INPUT -i incusbr0 -j ACCEPT
    -A INPUT -p icmp -j ACCEPT
    # fail2ban 动态 ban 链（先于放行）
    -A INPUT -j f2b-sshd
    # 放行服务端口
    -A INPUT -p tcp --dport 22 -j ACCEPT
    -A INPUT -p tcp --dport 8443 -j ACCEPT
    # derper（C2）：DERP TCP 10043 + STUN UDP 10078
    -A INPUT -p tcp --dport 10043 -j ACCEPT
    -A INPUT -p udp --dport 10078 -j ACCEPT
    # 其余拒绝并记录
    -A INPUT -j LOG --log-prefix "sm-input-dropped: " --log-level 4
    -A INPUT -j DROP
    COMMIT
  '';

  systemd.services.sm-firewall = {
    enable = true;
    description = "Apply declarative iptables inbound rules";
    wantedBy = [ "system-manager.target" ];
    before = [ "fail2ban.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # iptables-restore -f（flush+load）先清旧规则再应用 —— 必须 flush！
      # 否则 iptables-save 里旧的无条件 ACCEPT（云盾/系统插入）残留，把未放行端口也放行
      # （实测：INPUT 有 3 条无条件 ACCEPT 残留，9999 端口可达）。flush 后只有声明规则
      # + fail2ban 的 f2b-sshd 链（备份恢复）。
      ExecStart = "${pkgs.iptables}/bin/iptables-restore /etc/iptables/sm-input.rules";
    };
  };
}
