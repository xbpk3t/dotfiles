{ pkgs, ... }:
{
  # 启动 `services.tuptime` 计时器 | 适合桌面统计 uptime，对服务器没有必需价值，却额外拉入 `tuptime` 及 `tuptime-sync.timer`
  environment.systemPackages = with pkgs; [
    tuptime
  ];

  services.tuptime = {
    enable = true;
    timer = {
      enable = true;
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
