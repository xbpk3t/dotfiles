{
  config,
  lib,
  pkgs,
  myvars,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.networking.singbox;
  client = import ../../../lib/singbox/client-config.nix {
    inherit
      config
      myvars
      mylib
      lib
      pkgs
      ;
  };
in {
  # https://mynixos.com/nixpkgs/options/services.sing-box

  # 只有desktop才需要引入singbox（因为所有VPS默认本身都不需要挂singbox），所以放在这里
  options.modules.networking.singbox = {
    enable = mkEnableOption "sing-box proxy service";
  };

  config = mkIf cfg.enable {
    # systemctl status sing-box.service
    # sudo journalctl -u sing-box -n 50 --no-pager
    services.sing-box = {
      enable = true;
      settings = client.configJson;
    };
  };
}
