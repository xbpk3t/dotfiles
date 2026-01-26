{
  nixos-vps = {
    nixos-vps-dev = {
      hostName = "nixos-vps-dev";
      primaryIp = "142.171.154.61";
      hardware = {
        cpuCores = 5;
        memGiB = 6;
        bwMbps = 800;
        rttMs = 1;
      };
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
      primaryIp = "103.85.224.63";
      hardware = {
        cpuCores = 4;
        memGiB = 4;
        bwMbps = 18;
        rttMs = 20;
      };
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
