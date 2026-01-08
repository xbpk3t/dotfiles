_: rec {
  nameservers = [
    "119.29.29.29"
    "223.5.5.5"
    "2400:3200::1"
    "2606:4700:4700::1111"
  ];

  singboxServers = [
    {
      hostName = "nixos-vps-142-171-154-61";
      label = "LA (RN)";
      server = "142.171.154.61";
      port = 8443;
      cf = {
        domain = "cf-la.lucc.dev";
        port = 2053;
        wsPath = "/ws";
      };
    }
    {
      hostName = "nixos-vps-103-85-224-63";
      label = "HK (hdy)";
      server = "103.85.224.63";
      port = 8443;

      # https://cf-la.lucc.dev:2053/ws
      cf = {
        domain = "cf-hk.lucc.dev";
        port = 2053;
        wsPath = "/ws";
      };
    }
  ];
}
