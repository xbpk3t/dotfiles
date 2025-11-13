#{
#  config,
#  lib,
#  pkgs,
#  ...
#}: let
#  tunnelId = "8a3a09c5-3fa3-4488-ba53-541482b1427e";
#  credentialsFile = "/home/luck/.cloudflared/${tunnelId}.json";
#  cfg = config.services.cloudflared;
#  tunnelUnitName = "cloudflared-tunnel-${tunnelId}";
#in {
#  # https://mynixos.com/nixpkgs/options/services.cloudflared
#  services.cloudflared = {
#    enable = true;
#    package = pkgs.cloudflared;
#    tunnels.${tunnelId} = {
#      inherit credentialsFile;
#      originRequest = {
#        connectTimeout = "15s";
#        tlsTimeout = "10s";
#        tcpKeepAlive = "30s";
#        keepAliveConnections = 64;
#        noHappyEyeballs = true;
#      };
#      ingress = {
#        "alist.lucc.dev" = {
#          service = "http://127.0.0.1:5244";
#        };
#      };
#      default = "http_status:404";
#    };
#  };
#
#  systemd.services.${tunnelUnitName} = lib.mkIf cfg.enable (
#    let
#      tunnelCfg = cfg.tunnels.${tunnelId};
#      ingressList =
#        lib.mapAttrsToList (
#          hostname: rule:
#            if builtins.isString rule
#            then {
#              inherit hostname;
#              service = rule;
#            }
#            else
#              {
#                inherit hostname;
#              }
#              // rule
#        )
#        tunnelCfg.ingress;
#      warpRoutingCfg = lib.attrByPath ["warp-routing"] {} tunnelCfg;
#      originRequestCfg = lib.attrByPath ["originRequest"] {} tunnelCfg;
#      http2Config = {
#        tunnel = tunnelId;
#        "credentials-file" = "/run/credentials/${tunnelUnitName}.service/credentials.json";
#        protocol = "http2";
#        "edge-ip-version" = "4";
#        "ha-connections" = 2;
#        warp-routing = warpRoutingCfg;
#        originRequest = originRequestCfg;
#        ingress =
#          ingressList
#          ++ [
#            {
#              service = tunnelCfg.default;
#            }
#          ];
#      };
#      http2ConfigFile =
#        pkgs.writeText "cloudflared-${tunnelId}-http2.json" (builtins.toJSON http2Config);
#    in {
#      serviceConfig.ExecStart = lib.mkForce ''${cfg.package}/bin/cloudflared tunnel --config=${http2ConfigFile} --no-autoupdate run'';
#    }
#  );
#}
{}
