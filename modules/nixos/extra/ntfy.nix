{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.ntfy;
  ingressDomain =
    if cfg.ingress == null
    then null
    else (cfg.ingress.domain or null);
  ingressUrl =
    if ingressDomain == null || ingressDomain == ""
    then null
    else "https://${ingressDomain}";
in {
  # https://mynixos.com/nixpkgs/options/services.ntfy-sh
  # https://mynixos.com/nixpkgs/package/ntfy-sh

  options.modules.services.ntfy = {
    enable = mkEnableOption "ntfy self-hosted push server";

    settings = mkOption {
      type = types.attrs;
      default = {};
      example = {
        baseUrl = "https://ntfy.example.com";
        settings = {
          cacheFile = "/var/lib/ntfy/cache.db";
          enableMetrics = true;
        };
      };
      description = "Pass-through options merged into services.ntfy-sh.* (except enable).";
    };

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "ntfy");
      default = null;
      description = "Expose ntfy through the shared reverse proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services."ntfy-sh" = mkMerge [
        {enable = true;}
        (mkIf (ingressUrl != null) {
          settings.baseUrl = ingressUrl;
        })
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.ntfy";
        ingress = cfg.ingress;
      })
    )
  ];
}
