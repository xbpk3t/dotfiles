{
  config,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.services.nezha;
in {
  # https://mynixos.com/nixpkgs/package/nezha-agent
  # https://mynixos.com/nixpkgs/options/services.nezha-agent

  # https://mynixos.com/nixpkgs/package/nezha-theme-admin
  # https://github.com/hamster1963/nezha-dash
  # https://mynixos.com/nixpkgs/package/nezha-theme-nazhua
  # https://mynixos.com/nixpkgs/package/nezha

  # https://github.com/nezhahq/nezha

  options.modules.services.nezha = {
    enable = mkEnableOption "Nezha monitoring agent";

    settings = mkOption {
      type = types.attrs;
      default = {};
      example = {
        package = "pkgs.nezha-agent";
        server = "nezha.example.com";
        tls.enable = true;
        secret = "/run/secrets/nezha";
      };
      description = "Pass-through options merged into services.nezha-agent.* (except enable).";
    };

    ingress = mkOption {
      type = types.nullOr (mylib.ingressOption "Nezha");
      default = null;
      description = "Expose any Nezha dashboards you host locally via the shared proxy.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      services."nezha-agent" = cfg.settings // {enable = true;};
    })

    (
      mkIf (mylib.ingressEnabled cfg.ingress)
      (mylib.mkReverseProxyIngress {
        modulePath = "modules.services.nezha";
        ingress = cfg.ingress;
      })
    )
  ];
}
