{
  inputs,
  mylib,
  lib,
  userMeta,
  pkgs,
  ...
}:
let
  cacheSettings = mylib.nixCacheSettings;
  inherit (userMeta) username;
in
{
  #
  # [nix - MyNixOS](https://mynixos.com/nix-darwin/options/nix)
  # [services.nix-daemon - MyNixOS](https://mynixos.com/nix-darwin/options/services.nix-daemon)
  #
  # Determinate uses its own daemon to manage the Nix installation that conflicts with nix-darwin’s native Nix management. To turn off nix-darwin’s management of the Nix installation.
  # ├─ 提供 determinateNix.* 选项、管理 /etc/nix/nix.custom.conf 与 determinate-nixd daemon。
  # └─ 【本模块所有 determinateNix.* 配置的类型来源】；不从 default.nix 引入，避免拆分后缺依赖。
  imports = [ inputs.determinate.darwinModules.default ];

  nix.enable = false;

  # 启用 Determinate Nix module，确保 nix.custom.conf / daemon 路径按官方方式管理。
  determinateNix = {
    enable = true;

    determinateNixd = {
      garbageCollector = {
        # 显式固定 Darwin 侧的 GC owner 为 Determinate Nixd。
        # why:
        # 1. 当前 Darwin 已经关闭 nix-darwin 自身的 Nix 管理（nix.enable = false）
        # 2. GC policy 如果只依赖上游 default，后续升级时语义可能漂移
        # 3. 在仓库里写明 strategy，后续排查时能直接从 config 看出 owner
        strategy = "automatic";
      };
    };

    # Determinate Nix 官方入口：由 module 生成并管理 /etc/nix/nix.custom.conf。
    customSettings = {
      # 允许信任 flake.nix 的 nixConfig（如 substituters / trusted-public-keys）
      accept-flake-config = true;

      # 允许当前用户读取受限配置并使用额外缓存
      trusted-users = [
        "root"
        username
      ];

      # 系统级 cache：确保 deploy-rs / nix run 也能命中
      inherit (cacheSettings) substituters;
      trusted-public-keys = cacheSettings.trustedPublicKeys;

      # 允许非 trusted user 也可以使用这些 substituters（避免 untrusted substituter 警告）
      trusted-substituters = cacheSettings.substituters;
    };
  };

  # Why:
  # 在 Darwin + Determinate Nix 场景下，/etc/static/nix/nix.custom.conf 更新后，
  # 偶发会出现 nix-daemon 仍沿用旧配置（典型症状：忽略 cache.numtide.com 并退回本地编译）。
  # 这里通过配置文件 hash 变更检测，做到“仅在必要时”重启 daemon。
  #
  # 注意：必须挂在 extraActivation（而非自定义 activationScripts 名）下。
  # nix-darwin 26.11 的 system.activationScripts.script.text 是静态模板，
  # 只拼接内置脚本 + extraActivation；用户自定义名（如 restartNixDaemonIfConfigChanged）
  # 不会被渲染进最终 activate，导致脚本从未执行（表现为 /var/db/determinate-nix/ 不存在）。
  system.activationScripts.extraActivation.text = lib.mkAfter ''
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

}
