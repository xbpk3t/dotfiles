{lib, ...}: let
  upstream = port: "http://127.0.0.1:${toString port}";

  # Per‑vhost defaults so adding new domains only requires mkProxy entry.
  vhostDefaults = {
    enableACME = true;
    addSSL = false;
    forceSSL = true;
    kTLS = true;
    http2 = true;
    http3 = true;
    quic = true;
    listen = lib.mkDefault [
      {
        addr = "0.0.0.0";
        port = 80;
        ssl = false;
      }
      {
        addr = "0.0.0.0";
        port = 443;
        ssl = true;
      }
    ];
  };

  mkProxy = port:
    vhostDefaults
    // {
      locations."/" = {
        proxyPass = upstream port;
        proxyWebsockets = true;
      };
    };

  # ACME 邮箱：ACME 需要在评估期得到明文，sops 路径位于运行时的 /run/secrets 无法在纯求值里读取，
  # 因此直接使用用户提供的邮箱字符串（邮箱本身不敏感）。
  acmeEmail = "yyzw@live.com";
in {
  # https://mynixos.com/nixpkgs/options/services.nginx
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "beszel.lucc.dev" = mkProxy 8090;
      "rsshub.lucc.dev" = mkProxy 1200;
      "pan.lucc.dev" = mkProxy 5244;
      "pt.lucc.dev" = mkProxy 9443;
      "n8n.lucc.dev" = mkProxy 5678;

      # "rss.lucc.dev" = mkProxy 5254;
      # "uptime.lucc.dev" = mkProxy 3001;
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = acmeEmail;
  };

  # Avoid strict overcommit which caused nix-daemon forks to fail ("Cannot allocate memory").
  boot.kernel.sysctl = {
    "vm.overcommit_memory" = lib.mkForce 0;
    "vm.overcommit_ratio" = lib.mkForce 100;
  };

  networking.firewall.allowedTCPPorts = lib.mkAfter [80 443];
}
