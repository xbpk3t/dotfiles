{...}: {
  # https://mynixos.com/home-manager/options/services.remmina

  #  services.remmina = {
  #    enable = true; # Enables Remmina
  #    package = pkgs.remmina; # Uses the default Remmina package from nixpkgs
  #  };
  #
  #  # Ensure the Remmina package is available
  #  home.packages = with pkgs; [
  #    remmina # Explicitly include the Remmina package
  #    freerdp # required by remmina
  #
  #    # FIXME [2025-10-12] rustdesk目前有bug，会报错 Wayland requires higher version of linux distro. Please try X11 desktop or change your OS. 等待fix，fix之后再使用
  #    # https://github.com/rustdesk/rustdesk/discussions/12897
  #    # rustdesk
  #  ];
}
