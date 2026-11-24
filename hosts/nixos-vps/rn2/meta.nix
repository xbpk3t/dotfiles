# nixos-vps-rn2: RackNerd LA KVM (HostPapa AS36352), 1 vCPU / 1 GiB / 20 GiB.
# Node name is derived from the path; do not add hostName here.
let
  ip = "192.236.224.187";
in
{
  kind = "nixos";
  system = "x86_64-linux";
  stateVersion = "26.05";

  tailscale = {
    ip = "100.113.219.86";
    role = "vps";
  };
  publicIpv4 = ip;

  deploy = {
    # 1 vCPU / 1 GiB: never build closures on the target.
    remoteBuild = false;
    # 无人值守部署的全局 smoke：配置最薄，适合先验证 activation/SSH/Tailscale。
    auto = true;
  };

  # Full protocol set; singbox-server.nix derives the inbounds, firewall
  # ports and ACME certificates directly from these fields.
  singbox = {
    label = "LA-RN2";
    server = ip;
    vlessPort = 8443;
    hy2 = {
      domain = "hy2-nixos-vps-rn2.lucc.dev";
      port = 8500;
    };
    vmessWs = {
      domain = "vmess-nixos-vps-rn2.lucc.dev";
      port = 9443;
      path = "/vmess";
    };
    tuic = {
      domain = "tuic-nixos-vps-rn2.lucc.dev";
      port = 10443;
    };
    anytls = {
      domain = "anytls-nixos-vps-rn2.lucc.dev";
      port = 11443;
    };
  };
}
