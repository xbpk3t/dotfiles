# nixos-vps-agt: fleet-visible facts only.
# 节点名由路径 hosts/nixos-vps/agt 派生为 nixos-vps-agt。
{
  kind = "nixos";
  system = "x86_64-linux";
  stateVersion = "26.05";

  tailscale.ip = "100.66.22.92";
  deploy = {
    sshUser = "root";
    remoteBuild = true;
  };

  # Mac 的 ssh.nix 读取该字段；只对交互式高延迟 host opt-in。
  ssh.multiplex = true;
}
