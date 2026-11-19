# nixos-vps-dev: fleet-visible facts only.
# 节点名由路径 hosts/nixos-vps/dev 派生为 nixos-vps-dev；
# 不要在这里再写 hostName。
{
  kind = "nixos";
  system = "x86_64-linux";
  stateVersion = "24.11";

  tailscale = {
    ip = "100.101.189.7";
    role = "vps";
  };

  # 公网 IPv4：TF DNS / sing-box 记录从这里生成。
  # dev 不再跑 derper（DERP 只保留 agt，见 terranix.nix 的 derpMap）。
  publicIpv4 = "192.129.183.26";

  deploy = {
    remoteBuild = true;
  };

  # Nezha 只允许一个 hub；agent 的 dashboard 地址从这里派生。
  nezha.hub = true;

  singbox = {
    label = "LA-RN";
    server = "192.129.183.26";
    vlessPort = 8443;
    hy2 = {
      domain = "hy2-nixos-vps-dev.lucc.dev";
      port = 8500;
    };
    vmessWs = {
      domain = "vmess-nixos-vps-dev.lucc.dev";
      port = 9443;
      path = "/vmess";
    };
    tuic = {
      domain = "tuic-nixos-vps-dev.lucc.dev";
      port = 10443;
    };
    anytls = {
      domain = "anytls-nixos-vps-dev.lucc.dev";
      port = 11443;
    };
  };
}
