{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.networking.netbird;
in {
  options.modules.networking.netbird.enable =
    mkEnableOption "NetBird client (VPN mesh network) on this host";

  config = mkIf cfg.enable {
    # 本配置非必需，services.netbird 本身会安装 netbird，但是需要手动执行 netbird 相关命令时方便
    environment.systemPackages = with pkgs; [
      # 注意这里应是 netbird，而非 netbird-client
      netbird
    ];

    # 注意 nixos 本身支持 services.netbird.clients；darwin 只有单实例
    services.netbird = {
      enable = true;
      package = pkgs.netbird;
    };

    environment.shellAliases = {
      nbs = "netbird";
    };
  };
}
