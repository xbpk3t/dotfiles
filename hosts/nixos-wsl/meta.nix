# nixos-wsl: fleet-visible facts only.
# Windows Server 2022 PA 上的 WSL2 NixOS 开发机；无 disko/硬件配置，
# 启动由 NixOS-WSL 接管。
{
  kind = "nixos";
  system = "x86_64-linux";
  # 首装来自 NixOS-WSL 2605.7.2（26.05）；后续包集随仓库 unstable 走。
  stateVersion = "26.05";
  # 2026-11-17 首次 join 后 `tailscale ip -4`（节点名 nixos-wsl）。
  tailscale = {
    ip = "100.95.55.36";
    role = "ws";
  };
}
