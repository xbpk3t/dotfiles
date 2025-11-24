{pkgs, ...}: {
  # 启动 `services.tuptime` 计时器 | 适合桌面统计 uptime，对服务器没有必需价值，却额外拉入 `tuptime` 及 `tuptime-sync.timer`
  environment.systemPackages = with pkgs; [
    tuptime
  ];

  # https://mynixos.com/nixpkgs/options/services.tuptime
  # https://mynixos.com/nixpkgs/package/tuptime
  # https://github.com/rfmoz/tuptime
  services.tuptime = {
    enable = true;
    timer = {
      enable = true;
    };
  };

  # https://mynixos.com/nixpkgs/options/services.tzupdate
  # https://github.com/cdown/tzupdate
  # services.tzupdate = {
  #   enable = true;
  #   package = pkgs.tzupdate;
  #   timer = {
  #     # Automatically update timezone
  #     enable = true;
  #   };
  # };
}
