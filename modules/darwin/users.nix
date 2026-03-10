# Darwin user configuration
# Contains user configuration that can be shared between multiple hosts
{
  mylib,
  myvars,
  lib,
  pkgs,
  ...
}: let
  cacheSettings = mylib.nixCacheSettings;
in {
  # Default user configuration (can be overridden by host-specific settings)
  users.users = {
    # Main user configuration with defaults
    "${myvars.username}" = {
      home = "/Users/${myvars.username}";
      description = myvars.username;
      shell = lib.mkDefault (pkgs.zsh + "/bin/zsh");
      openssh.authorizedKeys.keys = myvars.SSHPubKeys;
    };

    # Note: Additional users should be created manually on macOS or via host-specific configuration
  };

  # Determinate Nix 官方入口：由 module 生成并管理 /etc/nix/nix.custom.conf。
  determinateNix.customSettings = {
    # 允许信任 flake.nix 的 nixConfig（如 substituters / trusted-public-keys）
    accept-flake-config = true;

    # 允许当前用户读取受限配置并使用额外缓存
    trusted-users = [
      "root"
      myvars.username
    ];

    # 系统级 cache：确保 deploy-rs / nix run 也能命中
    substituters = cacheSettings.substituters;
    trusted-public-keys = cacheSettings.trustedPublicKeys;

    # 允许非 trusted user 也可以使用这些 substituters（避免 untrusted substituter 警告）
    trusted-substituters = cacheSettings.substituters;
  };

  # Shell configuration - make shells available system-wide
  environment.shells = lib.mkDefault [
    (pkgs.zsh + "/bin/zsh")
    (pkgs.bash + "/bin/bash")
  ];

  environment.pathsToLink = lib.mkDefault [
    # "/share/zsh"
    # "/share/bash-completion"
    # "/share/nvim"
    # "/share/man"
  ];
}
