{lib}: let
  nodesOrEmpty = inventory: inventory.nodes or {};
  primaryHostForNode = name: node:
    node.primaryIp
    or node.ip
    or (
      if node ? ips && node.ips != []
      then builtins.head node.ips
      else null
    )
    or
    (node.ssh.host or null)
    or
    name;
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
    hostname = host;
    inherit sshUser sshOpts remoteBuild;
    profiles.system = {
      user = "root";
      path = deployLib.activate.nixos nixosConfiguration;
    };
  };
}
