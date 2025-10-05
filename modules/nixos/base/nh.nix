{
  lib,
  pkgs,
  myvars,
  ...
}: {
  # auto upgrade nix to the unstable version
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/tools/package-management/nix/default.nix#L284
  # nix.package = pkgs.nixVersions.latest;

  # https://lix.systems/add-to-config/
  # nix.package = pkgs.lix;

  # to install chrome, you need to enable unfree packages
  nixpkgs.config.allowUnfree = lib.mkForce true;

  # 使用 nh 来管理垃圾回收，禁用内置的 nix.gc
  nix.gc = {
    automatic = lib.mkDefault false; # 禁用内置 GC，使用 nh 代替
  };

  # Manual optimise storage: nix-store --optimise
  # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
  nix.settings.auto-optimise-store = true;

  nix.channel.enable = false; # remove nix-channel related tools & configs, we use flakes instead.

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
