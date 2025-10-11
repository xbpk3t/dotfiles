{
  pkgs,
  myvars,
  ...
}: {
  # Use sops-nix for secrets management instead of agenix
  # nix.extraOptions = ''
  #   !include ${config.sops.secrets.nix-access-tokens.path}
  # '';

  # Nix Helper (nh) configuration
  # https://github.com/viperML/nh
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 7d --keep 5";
    };
    flake = "/home/${myvars.username}/nix-config";
  };

  # Additional Nix management tools
  environment.systemPackages = with pkgs; [
    nix-output-monitor # Build progress visualization
    nvd # Nix version diff tool
  ];
}
