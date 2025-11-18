{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.frp;
in {
  # https://mynixos.com/nixpkgs/package/frp
  # https://mynixos.com/nixpkgs/options/services.frp

  options.modules.services.frp = {
    enable = mkEnableOption "Fast Reverse Proxy (frp)";

    settings = mkOption {
      type = types.attrs;
      default = {};
      example = {
        role = "server";
        package = "pkgs.frp";
        settings.serverAddr = "0.0.0.0";
      };
      description = "Pass-through options merged into services.frp.* (except enable).";
    };

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "FRP");
      default = null;
      description = "Expose the FRP dashboard/API behind the shared proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services.frp = cfg.settings // {enable = true;};
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.frp";
        ingress = cfg.ingress;
      })
    )
  ];
}
