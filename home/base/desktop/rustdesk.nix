{pkgs, ...}: {
  # https://mynixos.com/home-manager/options/services.remmina

  #  services.remmina = {
  #    enable = true; # Enables Remmina
  #    package = pkgs.remmina; # Uses the default Remmina package from nixpkgs
  #  };
  #
  # Ensure the Remmina package is available
  home.packages = with pkgs; [
    # remmina # Explicitly include the Remmina package
    # freerdp # required by remmina
  ];
}
