{}: let
  nodesOrEmpty = inventory: inventory.nodes or {};
  normalizeSingboxNode = name: node: let
    singbox = node.singbox;
  in
    singbox
    // {
      hostName = node.hostName or name;
      server = singbox.server or node.targetHost;
    };
in {
  singboxForHost = inventory: hostName: let
    nodes = nodesOrEmpty inventory;
    node = nodes.${hostName};
  in
    normalizeSingboxNode hostName node;
}
