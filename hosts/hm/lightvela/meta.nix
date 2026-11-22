# hm-lightvela: 厂商托管的 Vela 工作台（systemd-nspawn container）。
#
# 官方机器名：lightvela
# tailnet 节点名：hermes-wb
# tailnet IP：100.72.194.36
#
# 这台机器没有 boot/disk/root 的系统控制权，只能应用 Home Manager 层。
# 因此 kind = "home"：只产出 homeConfigurations，不产出
# nixosConfigurations / systemConfigs / deploy.nodes。
{
  kind = "home";
  system = "x86_64-linux";
  stateVersion = "26.05";

  # 部署驱动：kind=home 默认派生为 ansible-hm，这里显式写出便于阅读。
  # task nix:deploy:hm 会把它列入多选，并路由到 hosts/_base/hm/ansible
  # （PA 本地 nix-portable build + activate）；不会生成 deploy.nodes。
  deploy.driver = "ansible-hm";

  # fleet 可寻址事实；用于 tailnet/checks 和 deployRoutes 的 ansible inventory。
  tailscale = {
    ip = "100.72.194.36";
    role = "vps";
    # 平台预注册的 tailnet 设备名，与 fleet 路径派生的 hm-lightvela 不同。
    # terranix/ACL 按这个名字索引设备。
    hostname = "hermes-wb";
  };

  # 平台只授权 root（hermes-workbench-client），不是 fleet 全局身份 luck。
  # ssh.nix 生成 fleet SSH config 时按这个字段选登录用户。
  ssh.user = "root";
}
