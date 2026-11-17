{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.herdr-core;
  tomlFormat = pkgs.formats.toml { };
in
{
  # host:
  #   modules.devops.herdr-core.enable = true;
  #
  # Package: inputs.llm-agents（from-source build；cache.numtide.com 有缓存）。
  # herdr-core = headless terminal runtime + `hc` CLI。herdr-app（桌面/手机）通过
  # SSH 执行 `hc connect` 接入：无 TCP 端口、无账号/relay，SSH 就是安全边界。
  # Linux 上 core 自己用 `systemd-run --user` 起 transient service 并 enable-linger，
  # 不需要额外 systemd unit；VPS 用户已有 linger。
  # 可选配置: ~/.config/herdr-core/config.toml（shell / notes / draft_wait）。
  #
  # 注意：旧 herdr TUI 已移除；herdr-core 只服务 herdr-app（桌面/手机），
  # 旧 TUI 里的 agent 不会出现在 app/手机。
  options.modules.devops.herdr-core = with lib; {
    enable = mkEnableOption "Herdr core runtime (hc CLI; SSH-reachable by herdr-app)";

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = "Contents of ~/.config/herdr-core/config.toml (core only reads it).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr-core
    ];

    # core 只读该文件，不存在运行时写回，适合声明式管理。
    xdg.configFile."herdr-core/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "herdr-core-config.toml" cfg.settings;
    };
  };
}
