# nixos-vps-rn2: RackNerd LA KVM (HostPapa AS36352), 1 vCPU / 1 GiB / 20 GiB.
# Node name is derived from the path; do not add hostName here.
let
  ip = "192.236.224.187";
in
{
  kind = "nixos";
  system = "x86_64-linux";
  stateVersion = "26.05";

  # 硬件事实：sysctl mode 与 limits profile 由 memGiB 统一派生。
  hardware = {
    cpuCores = 1;
    memGiB = 1;
    bwMbps = 1000;
    rttMs = 150;
  };

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
  # ports and ACME certificates from these fields. Port/path defaults come
  # from lib/fleet (normalizeSingbox); only the domains vary per node.
  singbox = {
    label = "LA-RN2";
    hy2 = {
      domain = "hy2-nixos-vps-rn2.lucc.dev";
    };
    vmessWs = {
      domain = "vmess-nixos-vps-rn2.lucc.dev";
    };
    tuic = {
      domain = "tuic-nixos-vps-rn2.lucc.dev";
    };
    anytls = {
      domain = "anytls-nixos-vps-rn2.lucc.dev";
    };
  };
}
