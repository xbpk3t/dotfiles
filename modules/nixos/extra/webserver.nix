{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.reverseProxy;
  hostSpecType = types.submodule {
    options = {
      target = mkOption {
        type = types.str;
        description = "Upstream URL such as http://127.0.0.1:8080";
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Additional Caddy directives appended after the reverse_proxy block.";
      };
      disableTls = mkOption {
        type = types.bool;
        default = true;
        description = "Serve this host over plain HTTP (useful when TLS terminates elsewhere).";
      };
    };
  };
  hostNames = builtins.attrNames cfg.virtualHosts;
  hostEntries =
    map (
      domain: let
        hostCfg = cfg.virtualHosts.${domain};
      in {
        inherit domain;
        target = hostCfg.target;
        extraConfig = hostCfg.extraConfig;
        disableTls = hostCfg.disableTls;
      }
    )
    hostNames;
  proxyEnabled = cfg.enable || hostEntries != [];
  renderedHosts = listToAttrs (
    map (
      entry: let
        label =
          if entry.disableTls
          then "http://${entry.domain}"
          else entry.domain;
        commonBody =
          ''
            reverse_proxy ${entry.target}
          ''
          + (optionalString (entry.extraConfig != "") "\n${entry.extraConfig}");
      in {
        name = label;
        value = {
          extraConfig = commonBody;
        };
      }
    )
    hostEntries
  );
  needsHttps = lib.any (entry: entry.disableTls == false) hostEntries;
  firewallPorts =
    lib.optional (cfg.openFirewall && hostEntries != []) 80
    ++ lib.optional (cfg.openFirewall && needsHttps) 443;
in {
  options.modules.reverseProxy = {
    enable = mkEnableOption "Shared Caddy reverse proxy";
    package = mkOption {
      type = types.package;
      default = pkgs.caddy;
      description = "Caddy package derivation to use.";
    };
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
      type = types.attrsOf hostSpecType;
      default = {};
      description = "Auto-generated host map from modules.services.* ingress definitions.";
    };
  };

  config = mkIf proxyEnabled {
    services.caddy =
      {
        enable = true;
        package = cfg.package;
        globalConfig = cfg.extraGlobalConfig;
        virtualHosts = renderedHosts;
      }
      // optionalAttrs (cfg.email != null) {email = cfg.email;};

    networking.firewall.allowedTCPPorts =
      mkIf (cfg.openFirewall && hostEntries != []) (lib.unique firewallPorts);
  };
}
