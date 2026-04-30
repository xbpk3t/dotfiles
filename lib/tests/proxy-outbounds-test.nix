{lib}: let
  servers = [
    {
      label = "LA-RN";
      server = "1.2.3.4";
      vlessPort = 8443;
      hy2 = {
        domain = "hy2.example.com";
        port = 8500;
      };
      vmessWs = {
        domain = "vmess.example.com";
        port = 9443;
        path = "/vmess";
      };
      tuic = {
        domain = "tuic.example.com";
        port = 10443;
      };
      anytls = {
        domain = "anytls.example.com";
        port = 11443;
      };
    }
  ];

  singboxOutbounds = import ../singbox/outbounds.nix {
    inherit lib servers;
    uuid = "00000000-0000-0000-0000-000000000001";
    publicKey = "pubkey";
    shortId = "shortid";
    password = "shared-password";
    flyingbirdPassword = "unused";
  };

  mihomoOutbounds = import ../mihomo/outbounds.nix {
    inherit lib servers;
    uuid = "00000000-0000-0000-0000-000000000001";
    publicKey = "pubkey";
    shortId = "shortid";
    password = "shared-password";
  };

  singboxTags = map (o: o.tag) singboxOutbounds;
  mihomoTags = mihomoOutbounds.tags;
in {
  assertion =
    builtins.all (tag: builtins.elem tag singboxTags) [
      "LA-RN-vless"
      "LA-RN-hy2"
      "LA-RN-vmess"
      "LA-RN-tuic"
      "LA-RN-anytls"
    ]
    && builtins.all (tag: builtins.elem tag mihomoTags) [
      "LA-RN-vless"
      "LA-RN-hy2"
      "LA-RN-vmess"
      "LA-RN-tuic"
      "LA-RN-anytls"
    ];

  testResults = {
    inherit singboxTags mihomoTags;
  };
}
