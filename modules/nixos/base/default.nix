{
  mylib,
  lib,
  myvars,
  inputs,
  pkgs,
  ...
}: {
  imports = mylib.scanPaths ./.;

  # Additional Nix management tools
  environment.systemPackages = with pkgs; [
    nix-output-monitor # Build progress visualization
    nvd # Nix version diff tool

    deadnix # https://github.com/astro/deadnix
    statix # https://github.com/oppiliappan/statix
    alejandra # https://github.com/kamadorueda/alejandra

    # nix related
    #
    # it provides the command `nom` works just like `nix
    # with more details log output
    nix-output-monitor
    hydra-check # check hydra(nix's build farm) for the build status of a package
    nix-index # A small utility to index nix store paths
    nix-init # generate nix derivation from url
    # https://github.com/nix-community/nix-melt
    nix-melt # A TUI flake.lock viewer
    # https://github.com/utdemir/nix-tree
    nix-tree # A TUI to visualize the dependency graph of a nix derivation

    colmena # NixOS 远程部署工具

    nvd # https://mynixos.com/nixpkgs/package/nvd

    # nix-update # https://github.com/Mic92/nix-update 只适用于nix pkg的维护者，用于自动化更新包版本和哈希
  ];

  nix = {
    settings = {
      # Manual optimise storage: nix-store --optimise
      # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
      auto-optimise-store = true;
      connect-timeout = 10;
      log-lines = 25;
      min-free = 128000000;
      max-free = 1000000000;
      trusted-users = ["@wheel"];
    };
    extraOptions = "experimental-features = nix-command flakes";

    gc = {
      # 使用 nh 来管理垃圾回收，禁用内置的 nix.gc
      automatic = lib.mkDefault false;
      options = "--delete-older-than 8d";
    };

    # remove nix-channel related tools & configs, we use flakes instead.
    channel.enable = false;
  };

  nixpkgs.config = {
    allowUnfree = true;
    enableParallelBuilding = true;
    buildManPages = false;
    buildDocs = false;
  };

  programs.nix-index = {
    enable = true;
  };

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

  # nixos-cli - Modern NixOS management CLI
  # https://github.com/nix-community/nixos-cli
  # https://nix-community.github.io/nixos-cli/installation.html
  services.nixos-cli = {
    enable = true;
    config = {
      # Optional: Add shell aliases for convenience
      # These can be added to shell.nix or user's shell configuration
      # nixos build    - Build the system configuration
      # nixos switch   - Build and activate the system configuration
      # nixos test     - Build and test the system configuration (no bootloader)
      # nixos boot     - Build and set as boot default (activate on next boot)
      # nixos rollback - Rollback to the previous generation
      # nixos list     - List all generations
      # nixos clean    - Clean old generations
      aliases = {
        genlist = ["generation" "list"];
        switch = ["generation" "switch"];
        rollback = ["generation" "rollback"];
        gendel = ["generation" "delete"];
        gendelall = ["generation" "delete" "--all"];
        build = ["apply" "--no-activate" "--no-boot" "--output" "result"];
        test = ["apply" "--no-boot" "-y"];
      };

      apply = {
        use_nvd = true;
        use_nom = true;
        imply_impure_with_tag = true;
        use_git_commit_msg = true;
        ignore_dirty_tree = true;
      };
    };
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "NO_COLOR"
  '';

  # Install nixos-cli package
  environment.systemPackages = [
    inputs.nixos-cli.packages.${pkgs.system}.default
  ];

  # Configure nixos-cli
  # Set the flake path for nixos-cli to use
  environment.sessionVariables = {
    FLAKE = "/home/${myvars.username}/Desktop/dotfiles";
  };
}
