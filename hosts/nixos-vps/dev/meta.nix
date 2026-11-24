# nixos-vps-dev: fleet-visible facts only.
# 节点名由路径 hosts/nixos-vps/dev 派生为 nixos-vps-dev；
# 不要在这里再写 hostName。
{
  kind = "nixos";
  system = "x86_64-linux";
  stateVersion = "24.11";

  # 硬件事实：sysctl mode 与 limits profile 由 memGiB 统一派生。
  hardware = {
    cpuCores = 5;
    memGiB = 6;
    bwMbps = 800;
    rttMs = 150;
  };

  tailscale = {
    ip = "100.101.189.7";
    role = "vps";
  };

  # 公网 IPv4：TF DNS 记录（api/as/rsshub）从这里生成。
  # dev 不再跑 derper（DERP 只保留 agt，见 terranix.nix 的 derpMap）。
  publicIpv4 = "192.129.183.26";

  deploy = {
    remoteBuild = true;
    # dev 是无人值守 runner 所在机器，不能由自己自动部署（self-deploy）。
    # 更新 dev 走手动：task nix:deploy NODES=nixos-vps-dev。
    auto = false;
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
