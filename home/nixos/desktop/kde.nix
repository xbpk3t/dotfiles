{pkgs, ...}: {
  # https://mynixos.com/home-manager/options/services.kdeconnect
  services.kdeconnect = {
    enable = true;
    indicator = true;
    package = pkgs.kdePackages.kdeconnect-kde;
  };
}
