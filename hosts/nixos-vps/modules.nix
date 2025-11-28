{lib, ...}: let
  upstream = port: "http://127.0.0.1:${toString port}";
  mkProxy = port: {
    locations."/" = {
      proxyPass = upstream port;
      proxyWebsockets = true;
    };
    # TLS is handled by Cloudflare, so keep origin HTTP only.
    forceSSL = false;
  };
in {
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;

    virtualHosts = {
      "beszel.lucc.dev" = mkProxy 8090;
      "rsshub.lucc.dev" = mkProxy 1200;
      "pan.lucc.dev" = mkProxy 5244;
      "ntfy.lucc.dev" = mkProxy 8020;

      # "rss.lucc.dev" = mkProxy 5254;
      # "uptime.lucc.dev" = mkProxy 3001;
    };
  };

  networking.firewall.allowedTCPPorts = lib.mkAfter [80 443];
}
