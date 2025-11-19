{
  config,
  lib,
  ...
}:
with lib; let
  inherit (lib.strings) trim splitString;
  cfg = config.modules.reverseProxy;
  hostNames = builtins.attrNames cfg.virtualHosts;
  needsHttps = any (domain: let host = cfg.virtualHosts.${domain}; in !(host.disableTls or true)) hostNames;
  firewallPorts =
    optional (cfg.openFirewall && hostNames != []) 80
    ++ optional (cfg.openFirewall && needsHttps) 443;

  indentBlock = text:
    if trim text == ""
    then ""
    else concatStringsSep "\n" (map (line: "  ${line}") (splitString "\n" (trim text)));

  hostBlocks =
    map (
      domain: let
        hostCfg = cfg.virtualHosts.${domain};
        label =
          if hostCfg.disableTls
          then "http://${domain}"
          else domain;
        body =
          ''
            reverse_proxy ${hostCfg.target}
          ''
          + (optionalString (hostCfg.extraConfig != "") "\n${hostCfg.extraConfig}");
      in ''
        ${label} {
        ${indentBlock body}
        }
      ''
    )
    hostNames;

  caddyConfigText = concatStringsSep "\n" (filter (segment: trim segment != "") hostBlocks);
in {
  options.modules.reverseProxy = {
    enable = mkEnableOption "Shared Caddy reverse proxy for containerized services";
    email = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Contact email for ACME certificates.";
    };
    extraGlobalConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Appended to services.caddy.globalConfig.";
    };
    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically open TCP/80 and TCP/443 when the proxy is active.";
    };
    virtualHosts = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          target = mkOption {
            type = types.str;
            description = "Upstream URL such as http://127.0.0.1:8080";
          };
          extraConfig = mkOption {
            type = types.lines;
            default = "";
            description = "Additional per-site Caddy directives.";
          };
          disableTls = mkOption {
            type = types.bool;
            default = true;
            description = "Serve this host over HTTP only (useful behind Cloudflare).";
          };
        };
      });
      default = {};
      description = "Virtual hosts aggregated from service ingress definitions.";
    };
  };

  config = mkIf (cfg.enable && hostNames != []) {
    services.caddy = {
      enable = true;
      email = cfg.email;
      globalConfig = cfg.extraGlobalConfig;
      extraConfig = caddyConfigText;
    };

    networking.firewall.allowedTCPPorts =
      mkIf cfg.openFirewall (lib.unique firewallPorts);
  };
}
