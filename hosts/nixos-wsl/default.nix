{
  inputs,
  mylib,
  ...
}:
{
  imports = [
    ../_base/nixos-wsl
    inputs.sops-nix.nixosModules.sops
    # NixOS-WSL：systemd、/etc/wsl.conf、Windows interop 都由它接管。
    inputs.nixos-wsl.nixosModules.default
    (mylib.relativeToRoot "secrets/default.nix")
  ];

  # 这台厂商 PA（Windows Server 2022）没有 host 专属服务：
  # hostname、Tailscale client、sops、user/nix 基线都由 _base/nixos-wsl 处理。
  # 以后要加 host 专属包/服务，在这里写。
}
