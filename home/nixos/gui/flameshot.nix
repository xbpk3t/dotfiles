{pkgs, ...}: {
  home.packages = with pkgs; [
    flameshot
  ];

  services.flameshot = {
    enable = true;
    package = pkgs.flameshot;
    settings = {
      General = {
        uiColor = "#1435c7";
        disabledTrayIcon = true;
        showStartupLaunchMessage = false;
      };
    };
  };
}
