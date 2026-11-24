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
}:
let
  baseLabel = s: s.label or (s.name or (s.tag or s.server));
  mkTag = proto: s: "${baseLabel s}-${proto}";

  toVlessOutbound = s: {
    name = mkTag "vless" s;
    type = "vless";
    inherit (s) server;
    port = s.vlessPort;
    inherit uuid;
    inherit flow;
    tls = true;
    client-fingerprint = fingerprint;
    servername = sni;
    reality-opts = {
      public-key = publicKey;
      short-id = shortId;
    };
  };

  toVmessOutbound =
    s:
    if !(s ? vmessWs) then
      null
    else
      let
        inherit (s) vmessWs;
      in
      {
        name = mkTag "vmess" s;
        type = "vmess";
        inherit (s) server;
        inherit (vmessWs) port;
        udp = true;
        inherit uuid;
        alterId = 0;
        cipher = "auto";
        packet-encoding = "packetaddr";
        global-padding = false;
        authenticated-length = false;
        tls = true;
        servername = vmessWs.domain;
        client-fingerprint = fingerprint;
        network = "ws";
        ws-opts = {
          inherit (vmessWs) path;
          headers = {
            Host = vmessWs.domain;
          };
        };
      };

  toHy2Outbound =
    s:
    if !(s ? hy2) then
      null
    else
      let
        inherit (s) hy2;
      in
      {
        name = mkTag "hy2" s;
        type = "hysteria2";
        inherit (s) server;
        inherit (hy2) port;
        inherit password;
        sni = hy2.domain;
        skip-cert-verify = false;
      }
      // (lib.optionalAttrs (hy2 ? up_mbps) { up = "${toString hy2.up_mbps}Mbps"; })
      // (lib.optionalAttrs (hy2 ? down_mbps) { down = "${toString hy2.down_mbps}Mbps"; });

  toTuicOutbound =
    s:
    if !(s ? tuic) then
      null
    else
      let
        inherit (s) tuic;
      in
      {
        name = mkTag "tuic" s;
        type = "tuic";
        inherit (s) server;
        inherit (tuic) port;
        inherit uuid password;
        alpn = [ "h3" ];
        request-timeout = 8000;
        udp-relay-mode = "native";
        congestion-controller = tuic.congestionControl;
        reduce-rtt = true;
        sni = tuic.domain;
        skip-cert-verify = false;
      };

  toAnytlsOutbound =
    s:
    if !(s ? anytls) then
      null
    else
      let
        inherit (s) anytls;
      in
      {
        name = mkTag "anytls" s;
        type = "anytls";
        inherit (s) server;
        inherit (anytls) port;
        inherit password;
        inherit (anytls) alpn;
        client-fingerprint = fingerprint;
        udp = true;
        sni = anytls.domain;
        skip-cert-verify = false;
      };

  vlessOuts = map toVlessOutbound servers;
  vmessOuts = lib.lists.filter (o: o != null) (map toVmessOutbound servers);
  hy2Outs = lib.lists.filter (o: o != null) (map toHy2Outbound servers);
  tuicOuts = lib.lists.filter (o: o != null) (map toTuicOutbound servers);
  anytlsOuts = lib.lists.filter (o: o != null) (map toAnytlsOutbound servers);

  outs = vlessOuts ++ vmessOuts ++ hy2Outs ++ tuicOuts ++ anytlsOuts;
in
{
  proxies = outs;
  tags = map (o: o.name) outs;
}
