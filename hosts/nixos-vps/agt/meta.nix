# nixos-vps-agt: fleet-visible facts only.
# 节点名由路径 hosts/nixos-vps/agt 派生为 nixos-vps-agt。
{
  kind = "nixos";
  system = "x86_64-linux";
  stateVersion = "26.05";

  tailscale.ip = "100.66.22.92";

  # 公网入口 IP：nva.lucc.dev / Tailscale DERP (Shanghai)。
  public.ipv4 = "1.15.64.188";

  deploy = {
    remoteBuild = true;
  };

  # Mac 的 ssh.nix 读取该字段；只对交互式高延迟 host opt-in。
  ssh.multiplex = true;
}
