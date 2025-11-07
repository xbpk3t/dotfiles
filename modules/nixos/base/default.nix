{
  mylib,
  lib,
  myvars,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nixos-cli.nixosModules.nixos-cli] ++ mylib.scanPaths ./.;

  # MAYBE https://github.com/triton/triton/blob/master/pkgs/all-pkgs/s/systemd/default.nix 这个配置太牛逼了，之后学着搞下

  # Additional Nix management tools
  environment.systemPackages = with pkgs; [
    # Install nixos-cli package
    inputs.nixos-cli.packages.${pkgs.system}.default

    nix-output-monitor # Build progress visualization

    deadnix # https://github.com/astro/deadnix
    statix # https://github.com/oppiliappan/statix
    alejandra # https://github.com/kamadorueda/alejandra

    # https://mynixos.com/nixpkgs/package/namaka
    # https://github.com/nix-community/namaka
    namaka

    # https://mynixos.com/nixpkgs/package/nixtract
    nixtract

    # https://mynixos.com/nixpkgs/package/nix-unit
    # https://github.com/nix-community/nix-unit
    #
    nix-unit

    # nix related
    #
    # it provides the command `nom` works just like `nix
    # with more details log output
    hydra-check # check hydra(nix's build farm) for the build status of a package
    nix-index # A small utility to index nix store paths
    nix-init # generate nix derivation from url
    # https://github.com/nix-community/nix-melt
    nix-melt # A TUI flake.lock viewer
    # https://github.com/utdemir/nix-tree
    nix-tree # A TUI to visualize the dependency graph of a nix derivation

    colmena # NixOS 远程部署工具

    nvd # https://mynixos.com/nixpkgs/package/nvd Nix version diff tool

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
      # https://github.com/NixOS/nix/issues/11728
      download-buffer-size = 524288000;
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      # GitHub API rate limit fix
      # To avoid API rate limits, set GITHUB_TOKEN environment variable
      # The token will be read from gh CLI if available
      # Usage: export GITHUB_TOKEN=$(gh auth token)
      # Or add to your shell profile for persistence
    '';

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
    flake = myvars.projectRoot;
  };

  # nixos-cli - Modern NixOS management CLI
  # https://github.com/nix-community/nixos-cli
  # https://nix-community.github.io/nixos-cli/installation.html
  # Note: nixos-cli is installed as a package (see environment.systemPackages above)
  # It provides commands like: nixos build, nixos switch, nixos test, etc.
  # Configuration is done via environment variables and config files
  services.nixos-cli = {
    enable = true;
    config = {
      use_nvd = true;
      ignore_dirty_tree = true;

      # Shell aliases for convenience
      aliases = {
        # Generation management
        sw = ["generation" "switch"];
        ls = ["generation" "list"];
        gendiff = ["generation" "diff"];
        rollback = ["generation" "rollback"];
        gendel = ["generation" "delete"];
        gendelall = ["generation" "delete" "--all"];

        # Apply/build operations
        build = ["apply" "--no-activate" "--no-boot" "--output" "result"];
        test = ["apply" "--no-boot" "-y"];
        boot = ["apply" "--no-activate" "-y"];
        dry = ["apply" "--dry"];
        vm = ["apply" "--vm"];

        # Information and query
        opt = ["option"];
        opts = ["option" "--non-interactive"];
        man = ["manual"];
      };

      apply = {
        imply_impure_with_tag = true;
        use_git_commit_msg = true;
        ignore_dirty_tree = true;
      };
    };
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "NO_COLOR"
  '';

  # Configure nixos-cli
  # Set the flake path for nixos-cli to use
  environment.sessionVariables = let
    projectPath = myvars.projectRoot;
  in {
    FLAKE = projectPath;
    NIXOS_CONFIG = projectPath;
  };
}
