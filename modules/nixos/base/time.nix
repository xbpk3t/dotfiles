{...}: {
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
