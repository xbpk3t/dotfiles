{ mylib, ... }:
{
  imports = map mylib.relativeToRoot [
    # 显式导入 homelab 需要的 infra 模块（取代旧 scanPaths 自动扫描）
    "modules/nixos/infra/tailscale-client.nix"
    "modules/nixos/infra/mihomo-server.nix"
    "modules/nixos/infra/singbox-server.nix"
    "modules/nixos/infra/btrbk.nix"
    "modules/nixos/infra/avahi.nix"
    "modules/nixos/infra/guix.nix"
    "modules/nixos/infra/nix-tools.nix"
  ];
}
