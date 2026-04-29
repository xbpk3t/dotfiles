{
  servers,
  lib,
  uuid,
  publicKey,
  shortId,
  sni ? "www.bing.com",
  flow ? "xtls-rprx-vision",
  fingerprint ? "chrome",
  hy2Password,
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
          password = hy2Password;
          sni = domain;
          skip-cert-verify = false;
        }
        // (lib.optionalAttrs (hy2 ? up_mbps) {up = "${toString hy2.up_mbps}Mbps";})
        // (lib.optionalAttrs (hy2 ? down_mbps) {down = "${toString hy2.down_mbps}Mbps";});

  vlessOuts = map toVlessOutbound servers;
  hy2Outs = lib.lists.filter (o: o != null) (map toHy2Outbound servers);

  outs = vlessOuts ++ hy2Outs;
in {
  proxies = outs;
  tags = map (o: o.name) outs;
}
