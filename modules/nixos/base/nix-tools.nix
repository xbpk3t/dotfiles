{
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [inputs.nixos-cli.nixosModules.nixos-cli];

  # MAYBE https://github.com/triton/triton/blob/master/pkgs/all-pkgs/s/systemd/default.nix 这个配置太牛逼了，之后学着搞下

  # Additional Nix management tools
  environment.systemPackages = with pkgs; [
    inputs.nixos-cli.packages.${pkgs.system}.default
  ];

  nix = {
    settings = {
      # Manual optimise storage: nix-store --optimise
      # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
      auto-optimise-store = true;
      connect-timeout = 10;
      log-lines = 25;

      # 构建过程中磁盘空间低于阈值时，临时触发 GC，直到回到 max-free
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

    # 定时GC
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

  # nixos-cli - Modern NixOS management CLI
  # https://github.com/nix-community/nixos-cli
  # https://nix-community.github.io/nixos-cli/installation.html
  # Note: nixos-cli is installed as a package (see environment.systemPackages above)
  # It provides commands like: nixos build, nixos switch, nixos test, etc.
  # Configuration is done via environment variables and config files
  # NIXOS_CONFIG="$HOME/Desktop/dotfiles" nixos apply
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

      # https://nix-community.github.io/nixos-cli/settings.html#apply
      apply = {
        imply_impure_with_tag = true;
        use_git_commit_msg = true;
        ignore_dirty_tree = true;
        # 使用 nom 来优化output
        use_nom = true;
      };
    };
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "NO_COLOR"
  '';
}
