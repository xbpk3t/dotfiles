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
      # 网络诊断工具 — tcpdump/openssl 已迁至 home/base/kernel/network.nix
    ];
  };
}
