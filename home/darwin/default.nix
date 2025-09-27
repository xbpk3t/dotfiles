{myvars, ...}: {
  # This module provides the base home-manager configuration
  # that will be imported by the system configuration

  home = {
    username = myvars.username;
    homeDirectory = "/Users/${myvars.username}";
    stateVersion = "24.05";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
