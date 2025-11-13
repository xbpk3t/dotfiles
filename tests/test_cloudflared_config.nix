let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;

  tunnelId = "8a3a09c5-3fa3-4488-ba53-541482b1427e";
  cfg = {
    enable = true;
    package = pkgs.cloudflared;
    tunnels = {
      ${tunnelId} = {
        credentialsFile = "/home/luck/.cloudflared/${tunnelId}.json";
        originRequest = {
          connectTimeout = "15s";
          tlsTimeout = "10s";
          tcpKeepAlive = "30s";
          keepAliveConnections = 64;
          noHappyEyeballs = true;
        };
        ingress = {
          "alist.lucc.dev" = {
            service = "http://127.0.0.1:5244";
          };
        };
        default = "http_status:404";
      };
    };
  };

  tunnelCfg = cfg.tunnels.${tunnelId};
  ingressList =
    lib.mapAttrsToList (
      hostname: rule:
        if builtins.isString rule
        then {
          inherit hostname;
          service = rule;
        }
        else
          {
            inherit hostname;
          }
          // rule
    )
    tunnelCfg.ingress;
  warpRoutingCfg = lib.attrByPath ["warp-routing"] {} tunnelCfg;
  originRequestCfg = lib.attrByPath ["originRequest"] {} tunnelCfg;
  http2Config = {
    tunnel = tunnelId;
    "credentials-file" = "/run/credentials/cloudflared-tunnel-${tunnelId}.service/credentials.json";
    protocol = "http2";
    "edge-ip-version" = "4";
    "ha-connections" = 2;
    warp-routing = warpRoutingCfg;
    originRequest = originRequestCfg;
    ingress =
      ingressList
      ++ [
        {
          service = tunnelCfg.default;
        }
      ];
  };
in
  builtins.toJSON http2Config
