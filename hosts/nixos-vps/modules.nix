{...}: let
  domainMap = {
    beszel = "beszel.lucc.dev";
    miniflux = "mf.lucc.dev";
    n8n = "n8n.lucc.dev";
    netdata = "netdata.lucc.dev";
    ntfy = "ntfy.lucc.dev";
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

  modules.services.uptime = {
    enable = true;
    ingress = {
      enable = true;
      domain = domain "uptime";
      target = upstream 3001;
    };
  };

  modules.services.miniflux = {
    enable = true;
    ingress = {
      enable = true;
      domain = domain "miniflux";
      target = upstream 5254;
    };
  };

  modules.services.beszel = {
    enable = false;
    ingress = {
      enable = true;
      domain = domain "beszel";
      target = upstream 8090;
    };
  };

  modules.services.n8n = {
    enable = false;
    ingress = {
      enable = true;
      domain = domain "n8n";
      target = upstream 5678;
    };
  };

  #  modules.services.netdata = {
  #    enable = false;
  #    listenAddress = "127.0.0.1";
  #    listenPort = 19999;
  #    ingress = {
  #      enable = true;
  #      domain = domain "netdata";
  #      target = upstream 19999;
  #    };
  #  };

  #  modules.services.ntfy = {
  #    enable = false;
  #    ingress = {
  #      enable = true;
  #      domain = domain "ntfy";
  #      target = upstream 2586;
  #    };
  #  };
}
