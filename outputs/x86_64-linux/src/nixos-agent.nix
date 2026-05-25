# nixos-agent 作为NixOS 容器运行在 nixos-vps 宿主机上。
# deploy node 由 nixos-vps.nix 的 mkNodeRole 从 host nixosConfig.containers.nixos-agent 复用求值结果生成，
# 避免 mylib.nixosSystem 单独求值导致的重复 eval。
{...}: {
  nixosConfigurations = {};
  deploy.nodes = {};
}
