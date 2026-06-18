{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.infra.networking;
in
{
  options.modules.infra.networking.enable =
    lib.mkEnableOption "Networking diagnostic tools (tcpdump)";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      # tcpdump 网络抓包
      # [2026-01-07] VPS上需要通过tcpdump抓包来排查问题，所以挪到core里
      tcpdump

      # 【2026-06-18】从 home/base/infra/default.nix 迁入，TLS 调试/证书管理
      openssl

    ];
  };
}
