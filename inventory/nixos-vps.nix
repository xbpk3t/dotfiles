{
  nodes = {
    nixos-vps-dev = {
      hostName = "nixos-vps-dev";
      targetHost = "142.171.154.61";
      tailscale = {
        derpDomain = "derp-nixos-vps-dev.lucc.dev";
      };
      singbox = {
        label = "LA-RN";
        server = "142.171.154.61";
        port = 8443;
        hy2 = {
          domain = "hy2-nixos-vps-dev.lucc.dev";
        };
      };
    };

    nixos-vps-svc = {
      hostName = "nixos-vps-svc";
      targetHost = "103.85.224.63";
      tailscale = {
        derpDomain = "derp-nixos-vps-svc.lucc.dev";
      };
      singbox = {
        label = "HK-hdy";
        server = "103.85.224.63";
        port = 8443;
        hy2 = {
          domain = "hy2-nixos-vps-svc.lucc.dev";
        };
      };
    };
  };
}
