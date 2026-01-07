_: rec {
  mainGateway = "192.168.5.1";
  mainGateway6 = "fe80::5";
  proxyGateway = "192.168.5.178";
  proxyGateway6 = "fe80::8";
  nameservers = [
    "119.29.29.29"
    "223.5.5.5"
    "2400:3200::1"
    "2606:4700:4700::1111"
  ];
  prefixLength = 24;
  singboxServers = [
    {
      label = "LA (RN)";
      server = "142.171.154.61";
      port = 8443;
      hy2 = {
        port = 8443;
        server_name = "hy2.lucc.dev";
      };
    }
    {
      label = "HK (hdy)";
      server = "103.85.224.63";
      port = 8443;
      hy2 = {
        port = 8443;
        server_name = "hy2.lucc.dev";
      };
    }
  ];
}
