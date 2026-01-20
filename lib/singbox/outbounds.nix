{
  servers,
  lib,
  uuid,
  publicKey,
  shortId,
  sni ? "www.bing.com",
  flow ? "xtls-rprx-vision",
  fingerprint ? "chrome",
  packetEncoding ? "xudp",
  hy2Password,
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
  addIf = cond: attrs:
    if cond
    then attrs
    else {};

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
  toHy2Outbound = s:
    if !(s ? hy2)
    then null
    else let
      hy2 = s.hy2;
      domain = hy2.domain or null;
      port = hy2.port or s.port or 8443;
    in
      if domain == null
      then throw "singbox: servers.*.hy2.domain is required"
      else
        {
          type = "hysteria2";
          tag = mkTag "hy2" s;
          server = s.server;
          server_port = port;
          password = hy2Password;
          tls = {
            enabled = true;
            server_name = domain;
            alpn = ["h3"];
          };
        }
        // (addIf (hy2 ? up_mbps) {up_mbps = hy2.up_mbps;})
        // (addIf (hy2 ? down_mbps) {down_mbps = hy2.down_mbps;});

  hy2Outs = lib.lists.filter (o: o != null) (map toHy2Outbound servers);

  # 用来存别人（比如机场）的nodes
  extraOutbounds = [
  ];

  outs = vlessOuts ++ hy2Outs ++ extraOutbounds;
in
  # 这里 builtins.seq 的写法是为了避免 deadnix 报错 unused var
  builtins.seq flyingbirdPassword (outs
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
    ])
