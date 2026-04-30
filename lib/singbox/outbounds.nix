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
  password,
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
  mkTag = proto: s: "${baseLabel s}-${proto}";
  addIf = cond: attrs:
    if cond
    then attrs
    else {};

  toVlessOutbound = s: let
    base = {
      type = "vless";
      tag = mkTag "vless" s;
      server = s.server;
      server_port = s.vlessPort;
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

  toVmessOutbound = s:
    if !(s ? vmessWs)
    then null
    else let
      vmess = s.vmessWs;
      domain = vmess.domain or null;
      port = vmess.port or null;
      path = vmess.path or null;
    in
      if domain == null || port == null || path == null
      then throw "singbox: servers.*.vmessWs.{domain,port,path} are required"
      else {
        type = "vmess";
        tag = mkTag "vmess" s;
        server = s.server;
        server_port = port;
        uuid = uuid;
        security = "auto";
        alter_id = 0;
        global_padding = false;
        authenticated_length = false;
        tls = {
          enabled = true;
          server_name = domain;
          utls = {
            enabled = true;
            fingerprint = fingerprint;
          };
        };
        transport = {
          type = "ws";
          path = path;
          headers = {
            Host = [domain];
          };
        };
      };

  vmessOuts = lib.lists.filter (o: o != null) (map toVmessOutbound servers);

  toHy2Outbound = s:
    if !(s ? hy2)
    then null
    else let
      hy2 = s.hy2;
      domain = hy2.domain or null;
      port = hy2.port or 8500;
    in
      if domain == null
      then throw "singbox: servers.*.hy2.domain is required"
      else
        {
          type = "hysteria2";
          tag = mkTag "hy2" s;
          server = s.server;
          server_port = port;
          password = password;
          tls = {
            enabled = true;
            server_name = domain;
            alpn = ["h3"];
          };
        }
        // (addIf (hy2 ? up_mbps) {up_mbps = hy2.up_mbps;})
        // (addIf (hy2 ? down_mbps) {down_mbps = hy2.down_mbps;});

  hy2Outs = lib.lists.filter (o: o != null) (map toHy2Outbound servers);

  toTuicOutbound = s:
    if !(s ? tuic)
    then null
    else let
      tuic = s.tuic;
      domain = tuic.domain or null;
      port = tuic.port or null;
      congestionControl = tuic.congestionControl or "bbr";
    in
      if domain == null || port == null
      then throw "singbox: servers.*.tuic.{domain,port} are required"
      else {
        type = "tuic";
        tag = mkTag "tuic" s;
        server = s.server;
        server_port = port;
        inherit uuid password;
        congestion_control = congestionControl;
        udp_relay_mode = "native";
        zero_rtt_handshake = false;
        heartbeat = "10s";
        tls = {
          enabled = true;
          server_name = domain;
          alpn = ["h3"];
        };
      };

  tuicOuts = lib.lists.filter (o: o != null) (map toTuicOutbound servers);

  toAnytlsOutbound = s:
    if !(s ? anytls)
    then null
    else let
      anytls = s.anytls;
      domain = anytls.domain or null;
      port = anytls.port or null;
      alpn = anytls.alpn or ["h2" "http/1.1"];
    in
      if domain == null || port == null
      then throw "singbox: servers.*.anytls.{domain,port} are required"
      else {
        type = "anytls";
        tag = mkTag "anytls" s;
        server = s.server;
        server_port = port;
        inherit password;
        tls = {
          enabled = true;
          server_name = domain;
          inherit alpn;
          utls = {
            enabled = true;
            fingerprint = fingerprint;
          };
        };
      };

  anytlsOuts = lib.lists.filter (o: o != null) (map toAnytlsOutbound servers);

  # 用来存别人（比如机场）的nodes
  extraOutbounds = [
  ];

  outs = vlessOuts ++ vmessOuts ++ hy2Outs ++ tuicOuts ++ anytlsOuts ++ extraOutbounds;
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
        # 高 CPU 现场里能看到明显的 5 分钟周期噪音，先把探测频率降下来，
        # 避免网络异常时 urltest 成为额外放大器。
        interval = "30m";
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
