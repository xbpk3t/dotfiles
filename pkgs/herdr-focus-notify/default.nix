{
  lib,
  rustPlatform,
  sources,
}:
let
  source = sources.herdr-focus-notify;
in
rustPlatform.buildRustPackage rec {
  # [yankewei/herdr-focus-notify: Clickable macOS notifications for Herdr agents](https://github.com/yankewei/herdr-focus-notify)
  # herdr plugin：agent blocked/done 时弹 macOS 可点击通知，点击聚焦对应 pane。
  # 运行时依赖 alerter（brew 管理，非 nix），通过 .env 的 HERDR_FOCUS_NOTIFY_NOTIFIER 注入路径。
  #
  # 使用方式（声明式接入 herdr，替代 `herdr plugin install github:...`）：
  #   herdr plugin link ${pkg}/plugin
  # 其中 ${pkg}/plugin 是带 herdr-plugin.toml 的插件目录（command 用 nix store 绝对路径）。
  # 注意：plugin link 注册一次即可，状态在 ~/.local/state/herdr/plugins，不随 nix 重建。

  pname = "herdr-focus-notify";
  version = "0.3.6";

  inherit (source) src;

  # 上游无 tag，version 由 nvfetcher 固定 commit。
  cargoHash = "sha256-tk5LORWI+R1DnYnAc/qGvrcJ6EnZJYlc1u/MmAXxsfY=";

  # 组装 herdr plugin 目录：$out/plugin/herdr-plugin.toml
  # manifest 里 command 用 $out 绝对路径（herdr 对绝对路径不做 cwd join）。
  postInstall = ''
    mkdir -p "$out/plugin"
    cat > "$out/plugin/herdr-plugin.toml" <<EOF
    id = "herdr-focus-notify"
    name = "Herdr Focus Notify"
    version = "0.3.6"
    min_herdr_version = "0.7.3"
    description = "Clickable desktop notifications that focus the relevant Herdr agent pane."
    platforms = ["macos"]

    [[actions]]
    id = "test"
    title = "Send test focus notification"
    command = ["$out/bin/herdr-focus-notify", "--test"]

    [[events]]
    on = "pane.agent_status_changed"
    command = ["$out/bin/herdr-focus-notify"]

    [[events]]
    on = "pane.focused"
    command = ["$out/bin/herdr-focus-notify"]
    EOF
  '';

  meta = with lib; {
    description = "Clickable macOS notifications for Herdr agents";
    homepage = "https://github.com/yankewei/herdr-focus-notify";
    license = licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "herdr-focus-notify";
  };
}
