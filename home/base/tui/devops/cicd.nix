{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # https://mynixos.com/nixpkgs/package/fluxcd
    # 
    # For flux cli
    fluxcd
  ];
}
