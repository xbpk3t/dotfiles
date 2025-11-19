{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  inherit (lib.strings) trim splitString;
  ensureAttrPath = secretName:
    if builtins.isList secretName
    then secretName
    else [secretName];

  secretPath = secretName:
    attrByPath
    (ensureAttrPath secretName ++ ["path"])
    (throw "Secret ${builtins.toString secretName} 未在 sops.secrets 中定义")
    config.sops.secrets;

  secretFileMap = secretEnv: mapAttrs (_: secretPath) secretEnv;

  rsshubCfg = config.modules.services.rsshub;
  minifluxCfg = config.modules.services.miniflux;
  reverseProxyCfg = config.modules.reverseProxy;

  hostNames = builtins.attrNames reverseProxyCfg.virtualHosts;
  needsHttps = any (domain: let host = reverseProxyCfg.virtualHosts.${domain}; in !(host.disableTls or true)) hostNames;
  firewallPorts =
    optional (reverseProxyCfg.openFirewall && hostNames != []) 80
    ++ optional (reverseProxyCfg.openFirewall && needsHttps) 443;

  indentBlock = text:
    if trim text == ""
    then ""
    else concatStringsSep "\n" (map (line: "  ${line}") (splitString "\n" (trim text)));

  hostBlocks =
    map (
      domain: let
        hostCfg = reverseProxyCfg.virtualHosts.${domain};
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

  mkIngressFor = {
    name,
    ingress,
  }:
    mkIf (mylib.ingressEnabled ingress) (mylib.mkReverseProxyIngress {
      modulePath = "modules.services.${name}";
      inherit ingress;
    });
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

  options.modules.services = {
    rsshub = {
      enable = mkEnableOption "RSSHub stack managed via nix-managed-docker-compose";
      ingress = mkOption {
        type = types.nullOr (mylib.ingressOption "RSSHub");
        default = null;
        description = "Expose RSSHub through the shared reverse proxy.";
      };
      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Literal substitutions passed to the compose file.";
      };
      secretEnv = mkOption {
        type = types.attrsOf (types.either types.str (types.listOf types.str));
        default = {
          YOUTUBE_KEY = "youtubeApiKey";
          YUQUE_TOKEN = "yuqueToken";
          GITHUB_ACCESS_TOKEN = "githubAccessToken";
          PIXIV_REFRESHTOKEN = "pixivRefreshToken";
          SPOTIFY_CLIENT_ID = "spotifyClientId";
          SPOTIFY_CLIENT_SECRET = "spotifyClientSecret";
        };
        description = "Map compose environment keys to entries in config.sops.secrets.";
      };
    };

    miniflux = {
      enable = mkEnableOption "Miniflux stack managed via nix-managed-docker-compose";
      ingress = mkOption {
        type = types.nullOr (mylib.ingressOption "Miniflux");
        default = null;
        description = "Expose Miniflux through the shared reverse proxy.";
      };
      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Literal substitutions passed to the compose file.";
      };
    };
  };

  config = mkMerge [
    (mkIf (rsshubCfg.enable || minifluxCfg.enable) {
      services.managedDockerCompose = {
        enable = mkDefault true;
        backend = "docker";
      };
    })

    (mkIf rsshubCfg.enable {
      services.managedDockerCompose.projects.rsshub = {
        composeFile = ./rsshub/compose.yml;
        substitutions = rsshubCfg.environment;
        substitutionsFromFiles = secretFileMap rsshubCfg.secretEnv;
      };
    })

    (mkIf minifluxCfg.enable {
      services.managedDockerCompose.projects.miniflux = {
        composeFile = ./miniflux/compose.yml;
        substitutions = minifluxCfg.environment;
      };
    })

    (mkIngressFor {
      name = "rsshub";
      ingress = rsshubCfg.ingress;
    })
    (mkIngressFor {
      name = "miniflux";
      ingress = minifluxCfg.ingress;
    })

    (mkIf (reverseProxyCfg.enable && hostNames != []) {
      services.caddy = {
        enable = true;
        email = reverseProxyCfg.email;
        globalConfig = reverseProxyCfg.extraGlobalConfig;
        extraConfig = caddyConfigText;
      };

      networking.firewall.allowedTCPPorts =
        mkIf reverseProxyCfg.openFirewall (lib.unique firewallPorts);
    })
  ];
}
