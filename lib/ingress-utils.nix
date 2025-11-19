_: let
  toMessage = modulePath: field: "${modulePath}.ingress.${field} must be set when ingress.enable = true.";
in {
  ingressEnabled = ingress: ingress != null && (ingress.enable or false);

  mkReverseProxyIngress = {
    modulePath,
    ingress,
  }: {
    assertions = [
      {
        assertion = ingress.domain != "";
        message = toMessage modulePath "domain";
      }
      {
        assertion = ingress.target != "";
        message = toMessage modulePath "target";
      }
    ];

    modules.reverseProxy.virtualHosts = {
      "${ingress.domain}" = {
        target = ingress.target;
        extraConfig = ingress.extraConfig;
        disableTls = ingress.disableTls;
      };
    };
  };
}
