{
  lib,
  inventoryData,
}: let
  nodesOrEmpty = inventory:
    if inventory == null
    then {}
    else inventory;
  inventory = nodesOrEmpty inventoryData;
  groupOrEmpty = name: inventory.${name} or {};
  # Why：inventory 是纯数据（分组内节点结构），可能同时提供 primaryIp/ip/ips/ssh.host。
  # What：按优先级挑一个“主机地址”作为部署/连接默认值。
  primaryHostForNode = name: node: let
    candidates = [
      (node.primaryIp or null)
      (node.ip or null)
      (
        if node ? ips && node.ips != []
        then builtins.head node.ips
        else null
      )
      (node.ssh.host or null)
      name
    ];
  in
    lib.findFirst (v: v != null) null candidates;
  normalizeSingboxNode = name: node: let
    singbox = node.singbox;
  in
    singbox
    // {
      hostName = node.hostName or name;
      server = singbox.server or primaryHostForNode name node;
    };
in {
  inherit primaryHostForNode;
  # 分组入口（简化调用）：mylib.inventory.<group>
  "nixos-vps" = groupOrEmpty "nixos-vps";
  "nixos-homelab" = groupOrEmpty "nixos-homelab";
  "nixos-ws" = groupOrEmpty "nixos-ws";
  "macos-ws" = groupOrEmpty "macos-ws";

  singboxForHost = inventory: hostName: let
    nodes = nodesOrEmpty inventory;
    node = nodes.${hostName};
  in
    normalizeSingboxNode hostName node;

  deployRsNode = {
    name,
    node,
    nixosConfiguration,
    deployLib,
    defaultSshUser ? "root",
    defaultSshPort ? null,
    remoteBuild ? true,
  }: let
    ssh = node.ssh or {};
    host = ssh.host or (primaryHostForNode name node);
    sshUser = ssh.user or defaultSshUser;
    sshPort = ssh.port or defaultSshPort;
    sshOpts = lib.optionals (sshPort != null) ["-p" (toString sshPort)];
  in {
    # What：部署目标地址（IP/域名/别名）。
    # Why：由 inventory 的 primaryIp/ip/ips/ssh.host 统一推导，避免重复填部署字段。
    hostname = host;
    # What：SSH 用户名。
    # Why：默认 root，允许每个节点覆盖（node.ssh.user）。
    sshUser = sshUser;
    # What：额外 SSH 参数（如端口）。
    # Why：deploy-rs 没有独立的 sshPort 字段，只能通过 sshOpts 传递。
    sshOpts = sshOpts;
    # What：是否在远端构建。
    # Why：与 Colmena 的 buildOnTarget 行为一致，避免本地负载。
    remoteBuild = remoteBuild;
    profiles.system = {
      # What：远端激活该 profile 的用户。
      # Why：NixOS 系统级激活必须以 root 执行。
      user = "root";
      # What：NixOS 系统 profile 的激活路径（系统 closure）。
      # Why：deploy-rs 通过 deployLib.activate.nixos 生成可执行的激活入口。
      path = deployLib.activate.nixos nixosConfiguration;
    };
  };
}
