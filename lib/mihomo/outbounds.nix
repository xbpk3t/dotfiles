{
  servers,
  lib,
  uuid,
  publicKey,
  shortId,
  sni ? "www.bing.com",
  flow ? "xtls-rprx-vision",
  fingerprint ? "chrome",
  password,
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

  toVlessOutbound = s: {
    name = mkTag "vless" s;
    type = "vless";
    server = s.server;
    port = s.vlessPort;
    uuid = uuid;
    flow = flow;
    tls = true;
    client-fingerprint = fingerprint;
    servername = sni;
    reality-opts = {
      public-key = publicKey;
      short-id = shortId;
    };
  };

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
      then throw "mihomo: servers.*.vmessWs.{domain,port,path} are required"
      else {
        name = mkTag "vmess" s;
        type = "vmess";
        server = s.server;
        port = port;
        udp = true;
        uuid = uuid;
        alterId = 0;
        cipher = "auto";
        packet-encoding = "packetaddr";
        global-padding = false;
        authenticated-length = false;
        tls = true;
        servername = domain;
        client-fingerprint = fingerprint;
        network = "ws";
        ws-opts = {
          path = path;
          headers = {
            Host = domain;
          };
        };
      };

  toHy2Outbound = s:
    if !(s ? hy2)
    then null
    else let
      hy2 = s.hy2;
      domain = hy2.domain or null;
      port = hy2.port or 8500;
    in
      if domain == null
      then throw "mihomo: servers.*.hy2.domain is required"
      else
        {
          name = mkTag "hy2" s;
          type = "hysteria2";
          server = s.server;
          port = port;
          password = password;
          sni = domain;
          skip-cert-verify = false;
        }
        // (lib.optionalAttrs (hy2 ? up_mbps) {up = "${toString hy2.up_mbps}Mbps";})
        // (lib.optionalAttrs (hy2 ? down_mbps) {down = "${toString hy2.down_mbps}Mbps";});

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
      then throw "mihomo: servers.*.tuic.{domain,port} are required"
      else {
        name = mkTag "tuic" s;
        type = "tuic";
        server = s.server;
        port = port;
        inherit uuid password;
        alpn = ["h3"];
        request-timeout = 8000;
        udp-relay-mode = "native";
        congestion-controller = congestionControl;
        reduce-rtt = true;
        sni = domain;
        skip-cert-verify = false;
      };

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
      then throw "mihomo: servers.*.anytls.{domain,port} are required"
      else {
        name = mkTag "anytls" s;
        type = "anytls";
        server = s.server;
        port = port;
        inherit password alpn;
        client-fingerprint = fingerprint;
        udp = true;
        sni = domain;
        skip-cert-verify = false;
      };

  vlessOuts = map toVlessOutbound servers;
  vmessOuts = lib.lists.filter (o: o != null) (map toVmessOutbound servers);
  hy2Outs = lib.lists.filter (o: o != null) (map toHy2Outbound servers);
  tuicOuts = lib.lists.filter (o: o != null) (map toTuicOutbound servers);
  anytlsOuts = lib.lists.filter (o: o != null) (map toAnytlsOutbound servers);

  outs = vlessOuts ++ vmessOuts ++ hy2Outs ++ tuicOuts ++ anytlsOuts;
in {
  proxies = outs;
  tags = map (o: o.name) outs;
}
