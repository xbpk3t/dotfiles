{lib, ...}:
with lib; {
  # https://mynixos.com/nixpkgs/package/frp
  # https://mynixos.com/nixpkgs/options/services.frp

  options.modules.services.frp = {
    enable = mkEnableOption "Fast Reverse Proxy (frp)";
  };
}
