# 最小 systemPackages：证明 sm 能收敛可执行路径，体积可控。
{ pkgs, ... }:
{
  _file = ./packages.nix;

  environment.systemPackages = [
    pkgs.hello
  ];
}
