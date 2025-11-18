{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.n8n;
  ingressDomain =
    if cfg.ingress == null
    then null
    else (cfg.ingress.domain or null);
  ingressUrl =
    if ingressDomain == null || ingressDomain == ""
    then null
    else "https://${ingressDomain}";
in {
  # https://mynixos.com/nixpkgs/options/services.n8n
  # https://mynixos.com/nixpkgs/package/n8n

  # [基于 n8n 的开源自动化：以滴答清单同步 Notion 为例 ｜ 少数派会员 π+Prime](https://sspai.com/prime/story/automation-n8n)

  options.modules.services.n8n = {
    enable = mkEnableOption "n8n automation platform";

    settings = mkOption {
      type = types.attrs;
      default = {};
      example = {
        package = "pkgs.n8n";
        settings = {
          host = "127.0.0.1";
          port = 5678;
        };
        environment = {
          N8N_BASIC_AUTH_ACTIVE = true;
          N8N_EDITOR_BASE_URL = "https://n8n.example.com";
        };
      };
      description = "Pass-through options merged into services.n8n.* (except enable).";
    };

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "n8n");
      default = null;
      description = "Expose n8n via the shared reverse proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.n8n = mkMerge [
        {enable = true;}
        (mkIf (ingressUrl != null) {
          environment = {
            N8N_EDITOR_BASE_URL = ingressUrl;
            N8N_BASIC_AUTH_ACTIVE = true;
          };
        })
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.n8n";
        ingress = cfg.ingress;
      })
    )
  ];
}
