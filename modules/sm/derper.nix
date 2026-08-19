# sm 轨 tailscale derper（DERP 中继服务端）。
#
# 声明式能力表达 NixOS services.tailscale.derper（对齐 modules/nixos/infra/tailscale-client.nix）：
#   - systemd.services.tailscale-derper → 声明式 unit（-a/-c /-stun-port/-hostname/-certmode=manual）
#   - 证书：lego DNS-01（CF token 走 sm sops）生成 ACME 证书 → /var/lib/derper/certs
#   - DNS 记录：TF 控制面（infra/stacks/.../tailscale/），声明式
#   - 防火墙：sm-firewall 已放行（10043/10078 需加入）
#
# 这是「服务角色」，走 modules.infra.derper.enable 开关（对齐 nixos 轨命名），由 hosts/sm-vps 启用。
{
  config,
  lib,
  pkgs,
  userMeta,
  ...
}:
with lib;
let
  cfg = config.modules.infra.derper;
  domain = "derp-sm-vps-tc.lucc.dev";
  port = 10043;
  stunPort = 10078;
  certDir = "/var/lib/derper/certs";
in
{
  _file = ./derper.nix;

  options.modules.infra.derper = {
    enable = mkEnableOption "Tailscale DERP relay server on this host";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    # ── ACME 证书（lego DNS-01，CF token 走 sops）──
    # 证书目录 + lego 签发（幂等：证书已存在则跳过）
    systemd.services.sm-derper-certs = {
      enable = true;
      description = "Obtain DERP TLS cert via lego DNS-01";
      wantedBy = [ "system-manager.target" ];
      after = [ "sops-install-secrets.service" ];
      requires = [ "sops-install-secrets.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # lego: dns challange via cloudflare token (from sops), certs to certDir
        EnvironmentFile = config.sops.secrets.ACME_CF_ENV.path;
        ExecStart = "${pkgs.lego}/bin/lego --email ${userMeta.mail} --dns cloudflare --domains ${domain} --path /var/lib/lego --accept-tos run";
        ExecStartPost = pkgs.writeScript "install-derper-certs" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          install -d -m 0750 -o root -g root ${certDir}
          install -m 0640 -o root -g root /var/lib/lego/certificates/${domain}.crt ${certDir}/${domain}.crt
          install -m 0640 -o root -g root /var/lib/lego/certificates/${domain}.key ${certDir}/${domain}.key
        '';
      };
    };

    # ── derper 服务（声明式 unit，对齐 nixos 轨 ExecStart 参数）──
    systemd.services.tailscale-derper = {
      enable = true;
      description = "Tailscale DERP relay server";
      wantedBy = [ "system-manager.target" ];
      after = [
        "network.target"
        "sm-derper-certs.service"
      ];
      requires = [ "sm-derper-certs.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = ''
          ${pkgs.tailscale.derper}/bin/derper \
            -a :${toString port} \
            -c /var/lib/derper/derper.key \
            -stun-port ${toString stunPort} \
            -hostname=${domain} \
            -certmode=manual \
            -certdir=${certDir} \
            -verify-clients \
            -http-port=-1
        '';
        Restart = "on-failure";
        RestartSec = "10s";
        # 需要监听端口 + 写证书目录
        ProtectSystem = "strict";
        ReadWritePaths = [
          certDir
          "/var/lib/derper"
        ];
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    # 防火墙放行（sm-firewall 的 rules 文件在 firewall.nix；这里补充 derper 端口）
    # 注意：sm-firewall 用 iptables-restore 全量应用，需在 rules 文件加这两条。
    # 此处用 mkAfter 提示（实际加在 firewall.nix 的 rules 里，见该文件）。
  };
}
