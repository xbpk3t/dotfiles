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
      "rss.lucc.dev" = mkProxy 5254;
      "rsshub.lucc.dev" = mkProxy 1200;
      "uptime.lucc.dev" = mkProxy 3001;
      "ntfy.lucc.dev" = mkProxy 8020;
      "beszel.lucc.dev" = mkProxy 8090;
    };
  };

  networking.firewall.allowedTCPPorts = lib.mkAfter [80 443];
}
