{
  lib,
  inputs,
  mylib,
  pkgs,
  ...
}: let
  cacheSettings = mylib.nixCacheSettings;
in {
  imports = [inputs.nixos-cli.nixosModules.nixos-cli];

  # MAYBE: https://github.com/triton/triton/blob/master/pkgs/all-pkgs/s/systemd/default.nix 这个配置太牛逼了，之后学着搞下

  # Additional Nix management tools
  environment.systemPackages = with pkgs; [
    # NOTE: `pkgs.system` 是别名，已被上游标记弃用；改为 hostPlatform.system。
    inputs.nixos-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
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
      substituters = cacheSettings.substituters;
      trusted-public-keys = cacheSettings.trustedPublicKeys;
      # 允许非 trusted user 也可使用这些 cache（减少 untrusted substituter 警告）
      trusted-substituters = cacheSettings.substituters;
      # https://github.com/NixOS/nix/issues/11728
      download-buffer-size = 524288000;

      # 默认 max-jobs = 10，并行太高容易把内存打爆或触发 ulimit -u
      # https://nix.dev/manual/nix/2.28/command-ref/conf-file.html#conf-max-jobs
      max-jobs = 5;
      cores = 2;

      # 禁止 git dirty 输出（这个warn没意义）
      warn-dirty = false;

      # 允许信任 flake.nix 的 nixConfig（如 extra-substituters / extra-trusted-public-keys）
      accept-flake-config = true;
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

  # NOTE:
  # nixpkgs.config 已上移到 outputs/default.nix 的 pkgs 构造阶段，
  # 以兼容 home-manager.useGlobalPkgs + readOnlyPkgs 模式并消除评估警告。

  documentation.nixos.enable = lib.mkDefault false;
  # NOTE:
  # 关闭 NixOS options 文档生成（options.json）。
  # 这会规避当前 Nix 对 make-options-doc 派生出的 builtins.derivation context 警告。

  # nixos-cli - Modern NixOS management CLI
  # https://github.com/nix-community/nixos-cli
  # https://nix-community.github.io/nixos-cli/installation.html
  # Note: nixos-cli is installed as a package (see environment.systemPackages above)
  # It provides commands like: nixos build, nixos switch, nixos test, etc.
  # Configuration is done via environment variables and config files
  # NIXOS_CONFIG="$HOME/Desktop/dotfiles" nixos apply
  # NOTE: 新版 nixos-cli 模块已从 services.* 迁移到 programs.*
  # 保持同样语义，仅更新 option path 以消除 deprecation warning。
  programs.nixos-cli = {
    enable = true;
    # NOTE: config 已重命名为 settings（上游兼容性调整）
    settings = {
      use_nvd = true;
      ignore_dirty_tree = true;

      # Shell aliases for convenience
      aliases = {
        # Generation management
        sw = [
          "generation"
          "switch"
        ];
        ls = [
          "generation"
          "list"
        ];
        gendiff = [
          "generation"
          "diff"
        ];
        rollback = [
          "generation"
          "rollback"
        ];
        gendel = [
          "generation"
          "delete"
        ];
        gendelall = [
          "generation"
          "delete"
          "--all"
        ];

        # Apply/build operations
        build = [
          "apply"
          "--no-activate"
          "--no-boot"
          "--output"
          "result"
        ];
        test = [
          "apply"
          "--no-boot"
          "-y"
        ];
        boot = [
          "apply"
          "--no-activate"
          "-y"
        ];
        dry = [
          "apply"
          "--dry"
        ];
        vm = [
          "apply"
          "--vm"
        ];

        # Information and query
        opt = ["option"];
        opts = [
          "option"
          "--non-interactive"
        ];
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

    option-cache = {
      # NOTE:
      # nixos-cli 当前通过 unsafeDiscardStringContext 生成 options cache，
      # 在新版本 Nix 下会触发 builtins.derivation/options.json 的 context warning。
      # 先关闭该缓存以消除 warning（不影响 nixos-cli 的核心 apply/build 能力）。
      enable = false;
    };
  };

  security.sudo.extraConfig = ''
    Defaults env_keep += "NO_COLOR"
  '';
}
