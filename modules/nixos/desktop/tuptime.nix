{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.desktop.tuptime;
in
{
  options.modules.desktop.tuptime.enable = lib.mkEnableOption "tuptime uptime tracker";

  # 启动 `services.tuptime` 计时器 | 适合桌面统计 uptime，对服务器没有必需价值，却额外拉入 `tuptime` 及 `tuptime-sync.timer`
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tuptime ];

    services.tuptime = {
      enable = true;
      timer = {
        enable = true;
      };
    };
  };

  # services.tzupdate = {
  #   enable = true;
  #   package = pkgs.tzupdate;
  #   timer = {
  #     # Automatically update timezone
  #     enable = true;
  #   };
  # };
}
