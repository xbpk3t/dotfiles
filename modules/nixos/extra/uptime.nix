{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.uptime;
in {
  # https://mynixos.com/nixpkgs/options/services.uptime-kuma
  # https://mynixos.com/nixpkgs/package/uptime-kuma

  options.modules.services.uptime = {
    enable = mkEnableOption "Uptime Kuma status page";

    settings = mkOption {
      type = types.attrs;
      default = {};
      example = {
        settings = {
          dataDir = "/var/lib/uptime-kuma";
        };
        package = "pkgs.uptime-kuma";
      };
      description = "Pass-through options merged into services.uptime-kuma.* (except enable).";
    };

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "Uptime Kuma");
      default = null;
      description = "Expose Uptime Kuma through the shared reverse proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services."uptime-kuma" = mkMerge [
        {
          enable = true;
          settings.DATA_DIR = mkDefault "/var/lib/uptime-kuma";
        }
        cfg.settings
      ];
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.uptime";
        ingress = cfg.ingress;
      })
    )
  ];
}
