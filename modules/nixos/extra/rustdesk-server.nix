{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.rustdeskServer;
in {
  # https://mynixos.com/nixpkgs/package/rustdesk-server
  # https://mynixos.com/nixpkgs/options/services.rustdesk-server

  options.modules.services.rustdeskServer = {
    enable = mkEnableOption "RustDesk rendezvous/relay server";

    settings = mkOption {
      type = types.attrs;
      default = {};
      example = {
        package = "pkgs.rustdesk-server";
        hbbr.port = 21115;
        hbbs.port = 21114;
      };
      description = "Pass-through options merged into services.rustdesk-server.* (except enable).";
    };

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "RustDesk Server");
      default = null;
      description = "Expose the RustDesk admin dashboard/API behind the shared proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services."rustdesk-server" = cfg.settings // {enable = true;};
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.rustdeskServer";
        ingress = cfg.ingress;
      })
    )
  ];
}
