{
  mylib,
  pkgs,
  ...
}: {
  imports = [../init.nix] ++ mylib.scanPaths ./.;

  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/nixos-anywhere
    # 因为可能之后也会用mac作为核心控制端，所以直接放到base里，来多端复用（而非放到专门nixos的nix文件里）
    nixos-anywhere
  ];
}
