{
  servers,
  uuid,
  publicKey,
  shortId,
  sni ? "www.bing.com",
  flow ? "xtls-rprx-vision",
  fingerprint ? "chrome",
  packetEncoding ? "xudp",
  flyingbirdPassword,
}: let
  baseLabel = s:
    if s ? label
    then s.label
    else if s ? name
    then s.name
    else if s ? tag
    then s.tag
    else s.server;
  mkTag = proto: s: "${proto}-${baseLabel s}";

  toVlessOutbound = s: let
    base = {
      type = "vless";
      tag = mkTag "vless" s;
      server = s.server;
      server_port = s.port;
      uuid = uuid;
      flow = flow;
      tls = {
        enabled = true;
        server_name = sni;
        utls = {
          enabled = true;
          fingerprint = fingerprint;
        };
        reality = {
          enabled = true;
          public_key = publicKey;
          short_id = shortId;
        };
      };
    };
  in
    if packetEncoding == null
    then base
    else base // {packet_encoding = packetEncoding;};

  vlessOuts = map toVlessOutbound servers;

  extraOutbounds = [
    {
      tag = "Singapore-01";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56241;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
    {
      tag = "Singapore-02";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56242;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
    {
      tag = "Singapore-03";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56243;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
    {
      tag = "Singapore-04";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56244;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
    {
      tag = "Singapore-05";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56245;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
    {
      tag = "Singapore-06";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56246;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
    {
      tag = "Singapore-07";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56247;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
    {
      tag = "Singapore-08";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56248;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
    {
      tag = "Singapore-09";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56249;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
    {
      tag = "Singapore-10";
      type = "trojan";
      server = "fbxt0765gh0pielsss.ftisthebest.com";
      server_port = 56250;
      password = flyingbirdPassword;
      tls = {
        server_name = "fbxt0765gh0pielsss.ftisthebest.com";
        insecure = true;
        enabled = true;
      };
    }
  ];

  outs = vlessOuts ++ extraOutbounds;
in
  outs
  ++ [
    # urltest 负责测速与自动选优
    {
      type = "urltest";
      tag = "urltest";
      outbounds = map (o: o.tag) outs;
      url = "http://www.gstatic.com/generate_204";
      interval = "5m";
      tolerance = 50;
    }
    # select 保留手动选择，默认指向 urltest 以展示延迟
    {
      type = "selector";
      tag = "select";
      outbounds = ["urltest"] ++ map (o: o.tag) outs;
      default = "urltest";
    }
    {
      type = "selector";
      tag = "GLOBAL";
      outbounds = ["select"];
      default = "select";
    }
    {
      type = "direct";
      tag = "direct";
    }
  ]
