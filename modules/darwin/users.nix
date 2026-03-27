# Darwin user configuration
# Contains user configuration that can be shared between multiple hosts
{
  mylib,
  globals,
  lib,
  pkgs,
  userMeta,
  ...
}: let
  cacheSettings = mylib.nixCacheSettings;
  username = userMeta.username;
in {
  # Default user configuration (can be overridden by host-specific settings)
  users.users = {
    # Main user configuration with defaults
    "${username}" = {
      home = "/Users/${username}";
      description = username;
      shell = lib.mkDefault (pkgs.zsh + "/bin/zsh");
      openssh.authorizedKeys.keys = globals.auth.sshPublicKeys;
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
      username
    ];

    # 系统级 cache：确保 deploy-rs / nix run 也能命中
    substituters = cacheSettings.substituters;
    trusted-public-keys = cacheSettings.trustedPublicKeys;

    # 允许非 trusted user 也可以使用这些 substituters（避免 untrusted substituter 警告）
    trusted-substituters = cacheSettings.substituters;
  };

  # Why:
  # 在 Darwin + Determinate Nix 场景下，/etc/static/nix/nix.custom.conf 更新后，
  # 偶发会出现 nix-daemon 仍沿用旧配置（典型症状：忽略 cache.numtide.com 并退回本地编译）。
  # 这里通过配置文件 hash 变更检测，做到“仅在必要时”重启 daemon。
  system.activationScripts.restartNixDaemonIfConfigChanged.text = lib.mkAfter ''
    set -eu

    # 优先使用 Determinate Nix 生成的 static 配置；不存在时回退到标准 nix.conf。
    conf="/etc/static/nix/nix.custom.conf"
    [ -e "$conf" ] || conf="/etc/nix/nix.conf"
    [ -e "$conf" ] || exit 0

    # 持久化上次已应用配置的 hash，用于避免每次 activation 都重启 daemon。
    stamp_dir="/var/db/determinate-nix"
    stamp_file="$stamp_dir/nix-conf.sha256"
    mkdir -p "$stamp_dir"

    new_hash="$(${pkgs.coreutils}/bin/sha256sum "$conf" | awk '{print $1}')"
    old_hash=""
    [ -f "$stamp_file" ] && old_hash="$(cat "$stamp_file")"

    if [ "$new_hash" != "$old_hash" ]; then
      # 兼容不同安装入口的 service label：
      # - Determinate Nix: systems.determinate.nix-daemon
      # - 传统 Nix(Darwin): org.nixos.nix-daemon
      /bin/launchctl kickstart -k system/systems.determinate.nix-daemon 2>/dev/null \
        || /bin/launchctl kickstart -k system/org.nixos.nix-daemon 2>/dev/null \
        || true
      echo "$new_hash" > "$stamp_file"
    fi
  '';

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
