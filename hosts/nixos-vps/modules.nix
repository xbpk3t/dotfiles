{...}: let
  domainMap = {
    beszel = "beszel.lucc.dev";
    miniflux = "rss.lucc.dev";
    #    n8n = "n8n.lucc.dev";
    #    netdata = "netdata.lucc.dev";
    #    ntfy = "ntfy.lucc.dev";
    uptime = "uptime.lucc.dev";
  };
  domain = service: builtins.getAttr service domainMap;
  upstream = port: "http://127.0.0.1:${toString port}";
in {
  modules.reverseProxy = {
    enable = true;
    email = "yyzw@live.com";
    openFirewall = true;
  };

  modules.services.miniflux = {
    enable = true;
    ingress = {
      enable = true;
      domain = domain "miniflux";
      target = upstream 3000;
    };
  };
}
