# nixos-vps-agt: fleet-visible facts only.
# 节点名由路径 hosts/nixos-vps/agt 派生为 nixos-vps-agt。
{
  kind = "nixos";
  system = "x86_64-linux";
  stateVersion = "26.05";

  tailscale = {
    ip = "100.66.22.92";
    role = "vps";
  };

  # 公网 IPv4：TF DNS / DERP A 记录从这里生成。
  publicIpv4 = "1.15.64.188";

  # 短域名：nva = nixos-vps-agt；域名里不体现 derp。
  derper = {
    domain = "nva.lucc.dev";
    dnsKey = "nva";
    dnsComment = "Tailscale DERP (Shanghai, nixos-vps-agt)";
  };

  deploy = {
    remoteBuild = true;
    # 自动部署；DERP 关键节点，故障时优先看 job summary / 手动回滚。
    auto = true;
  };

  # Mac 的 ssh.nix 读取该字段；只对交互式高延迟 host opt-in。
  ssh.multiplex = true;
}
