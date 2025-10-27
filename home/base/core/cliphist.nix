{pkgs, ...}: {
  home.packages = with pkgs; [
    cliphist
  ];

  services.cliphist = {
    enable = true;
    package = pkgs.cliphist;
    allowImages = true;
  };
}
