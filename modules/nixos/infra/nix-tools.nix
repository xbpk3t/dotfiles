{
  config,
  lib,
  inputs,
  mylib,
  pkgs,
  ...
}:
let
  cacheSettings = mylib.nixCacheSettings;
  cfg = config.modules.infra.nix-tools;
in
{
  options.modules.infra.nix-tools = {
    enable = lib.mkEnableOption "Nix management tools (nixos-cli, cache settings, sudo env)";

    gc = {
      automatic = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the periodic Nix garbage collector.";
      };

      dates = lib.mkOption {
        type = lib.types.either lib.types.str (lib.types.listOf lib.types.str);
        default = "weekly";
        description = "systemd calendar expression(s) for the Nix GC timer.";
      };

      keepGenerations = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        description = ''
          Keep only the last N system generations before each GC run.

          nix-collect-garbage has no count-based option (only
          --delete-old/--delete-older-than), so this is implemented with
          `nix-env -p /nix/var/nix/profiles/system --delete-generations +N`
          in the nix-gc service's preStart. `null` disables count-based
          pruning.
        '';
      };

      maxAge = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "8d";
        description = ''
          Pass `--delete-older-than <maxAge>` to nix-collect-garbage
          (for example "7d"). Applies to every profile found under
          /nix/var/nix/profiles. `null` disables the age-based safety net.
        '';
      };

      optimise = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable periodic `nix store optimise` (retroactive hardlink dedup).";
      };

      minFree = lib.mkOption {
        type = lib.types.ints.positive;
        default = 128000000;
        description = "Free disk space (bytes) that triggers GC during builds.";
      };

      maxFree = lib.mkOption {
        type = lib.types.ints.positive;
        default = 1000000000;
        description = "Free disk space (bytes) that an automatic GC aims for.";
      };
    };
  };

  # nixos-cli module import 必须在顶层，不能包在 mkIf 里（否则触发 "option `imports' does not exist"——imports 只认模块顶层字段）。
  imports = [ inputs.nixos-cli.nixosModules.nixos-cli ];

  config = lib.mkIf cfg.enable {
    # Additional Nix management tools
    environment.systemPackages = with pkgs; [
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
        min-free = lib.mkDefault cfg.gc.minFree;
        max-free = lib.mkDefault cfg.gc.maxFree;
        trusted-users = [ "@wheel" ];
        inherit (cacheSettings) substituters;
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
        # To avoid API rate limits, export the sops-managed GITHUB_TOKEN in the shell.
      '';

      # 定时 GC。数量裁剪由 nix-env 完成（见下面 nix-gc.preStart），
      # nix-collect-garbage 本身只支持按时间 --delete-older-than。
      gc = {
        automatic = lib.mkDefault cfg.gc.automatic;
        dates = lib.mkDefault cfg.gc.dates;
        options = lib.mkDefault (
          lib.optionalString (cfg.gc.maxAge != null) "--delete-older-than ${cfg.gc.maxAge}"
        );
      };

      # 对已有路径做 retroactive hardlink 去重。
      optimise.automatic = lib.mkDefault cfg.gc.optimise;

      # remove nix-channel related tools & configs, we use flakes instead.
      channel.enable = false;
    };

    # nix-collect-garbage 没有 --delete-generations；按数量保留由 nix-env 完成。
    # 用 config.nix.gc.automatic 而不是 cfg.gc.automatic：host 层可能直接覆盖
    # nix.gc.automatic = false，此时不能凭空生成一个只有 preStart 的 nix-gc unit。
    systemd.services.nix-gc.preStart =
      lib.mkIf (config.nix.gc.automatic && cfg.gc.keepGenerations != null)
        ''
          ${config.nix.package}/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +${toString cfg.gc.keepGenerations}
        '';

    # nixpkgs.config 已上移到 outputs/default.nix 的 pkgs 构造阶段，
    # 以兼容 home-manager.useGlobalPkgs + readOnlyPkgs 模式并消除评估警告。

    # It provides commands like: nixos build, nixos switch, nixos test, etc.
    # Configuration is done via environment variables and config files
    # NIXOS_CONFIG="$HOME/Desktop/dotfiles" nixos apply
    # 新版 nixos-cli 模块已从 services.* 迁移到 programs.* 保持同样语义，仅更新 option path 以消除 deprecation warning。
    programs.nixos-cli = {
      enable = true;
      # config 已重命名为 settings（上游兼容性调整）
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
          opt = [ "option" ];
          opts = [
            "option"
            "--non-interactive"
          ];
          man = [ "manual" ];
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
        # nixos-cli 当前通过 unsafeDiscardStringContext 生成 options cache，
        # 在新版本 Nix 下会触发 builtins.derivation/options.json 的 context warning。
        # 先关闭该缓存以消除 warning（不影响 nixos-cli 的核心 apply/build 能力）。
        enable = false;
      };
    };

    security.sudo.extraConfig = ''
      Defaults env_keep += "NO_COLOR"
    '';

    # programs.nix-ld = {
    #   enable = true;
    #   libraries = with pkgs; [
    #     stdenv.cc.cc
    #     openssl
    #     zlib
    #   ];
    # };
  };
}
