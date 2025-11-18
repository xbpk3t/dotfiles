{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.miniflux;
  ingressDomain =
    if cfg.ingress == null
    then null
    else (cfg.ingress.domain or null);
  ingressUrl =
    if ingressDomain == null || ingressDomain == ""
    then null
    else "https://${ingressDomain}";
in {
  # https://mynixos.com/nixpkgs/options/services.miniflux
  # https://mynixos.com/nixpkgs/package/miniflux

  # Nextflux
  # https://github.com/electh/nextflux
  # https://github.com/electh/nextflux/blob/main/compose.yml

  # https://github.com/miniflux/v2/issues/2368
  # https://github.com/miniflux/v2/issues/2711
  # https://github.com/miniflux/v2/issues/2720
  # https://github.com/miniflux/v2/issues/2369
  # https://github.com/miniflux/v2/issues/2026
  # https://github.com/miniflux/v2/issues/2862
  # https://github.com/miniflux/v2/issues/2066
  # https://github.com/miniflux/v2/issues/2863
  # https://github.com/miniflux/v2/issues/2873
  # https://github.com/miniflux/v2/issues/2868
  # https://github.com/miniflux/v2/issues/2874

  # https://github.com/miniflux/v2/issues/2911
  # https://github.com/miniflux/v2/issues/2843
  # https://github.com/miniflux/v2/pull/2143
  # https://github.com/miniflux/v2/pull/2150
  # https://github.com/miniflux/v2/pull/2392
  # https://github.com/miniflux/v2/pull/2421
  # https://github.com/miniflux/v2/pull/2415

  options.modules.services.miniflux = {
    enable = mkEnableOption "Miniflux RSS reader";

    settings = mkOption {
      type = types.attrs;
      default = {};
      example = {
        adminCredentialsFile = "/run/secrets/miniflux-admin";
        config = {
          CLEANUP_ARCHIVE_UNREAD_DAYS = 90;
          BASE_URL = "https://feeds.example.com";
        };
        database = {
          type = "postgresql";
          host = "127.0.0.1";
          port = 5432;
        };
      };
      description = "Pass-through options merged into services.miniflux.* (except enable).";
    };

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "Miniflux");
      default = null;
      description = "Expose Miniflux through the shared reverse proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.miniflux = mkMerge [
        {
          enable = true;
          config.CREATE_ADMIN = 0;
        }
        (mkIf (ingressUrl != null) {
          config.BASE_URL = ingressUrl;
        })
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.miniflux";
        ingress = cfg.ingress;
      })
    )
  ];
}
