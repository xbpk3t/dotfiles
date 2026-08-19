# sm 轨 nginx 状态页（SGP fleet 状态）。
# sm 官方适配 services.nginx（upstream/nixpkgs 模块薄封装），可直接用。
# 状态数据：systemd timer 定期跑 `tailscale status --json` → 生成 fleet.json，
# nginx 静态提供（SGP 视角看 fleet 在线状态）。
# 这是「服务角色」，走 modules.infra.status-page.enable 开关。
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.infra.status-page;
  domain = "status.lucc.dev";
  stateDir = "/var/lib/status-page";
in
{
  _file = ./status-page.nix;

  options.modules.infra.status-page = {
    enable = mkEnableOption "nginx status page for fleet (SGP)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    systemd.services.sm-status-generator = {
      enable = true;
      description = "Generate fleet status JSON from tailscale";
      wantedBy = [ "system-manager.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        StateDirectory = "status-page";
        ExecStart = pkgs.writeScript "gen-fleet-status" ''
          #!${pkgs.bash}/bin/bash
          set -euo pipefail
          mkdir -p ${stateDir}
          ${pkgs.tailscale}/bin/tailscale status --json \
            | ${pkgs.jq}/bin/jq '{time: .Self.DNSName, peers: [.Peer[] | {name: .DNSName, online, tailscaleIPs, os: .OS}]}' \
            > ${stateDir}/fleet.json
        '';
      };
    };

    systemd.timers.sm-status-generator = {
      enable = true;
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        listen = [
          {
            addr = "0.0.0.0";
            port = 8080;
          }
        ];
        root = stateDir;
        locations."/".extraConfig = ''
          default_type application/json;
          # 纯 JSON 状态页，直接 serve fleet.json
          try_files /fleet.json =404;
        '';
      };
    };
  };
}
