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
  version = "0.8.0";

  inherit (source) src;

  # version 由 nvfetcher 跟踪上游 tag（见 nvfetcher.toml）；升级时同步 bump cargoHash。
  cargoHash = "sha256-cbxDZOvKLeEZ3raq1nMGioOv3+0ZLXNkAQ/wP2oLazQ=";

  # 上游 4 个集成用例依赖真实进程 spawn 时序（stub herdr/git 子进程 + 2s lookup
  # 预算 + 假 socket server），在 nix 沙箱里不稳定（已实测 TMPDIR/串行均无效）；
  # 上游 CI（普通 macOS 环境）全绿。这里只跳过这 4 个，其余 16 个照跑；
  # 上游若改善沙箱兼容性可移除。
  checkFlags = [
    "--skip=a_hanging_agent_lookup_still_sends_the_notification_within_the_budget"
    "--skip=a_hanging_worktree_lookup_delays_the_notification_by_the_budget_at_most"
    "--skip=normal_notification_names_the_pane_and_never_requests_an_explanation"
    "--skip=notification_content_click_runs_the_focus_helper"
  ];

  # 组装 herdr plugin 目录：$out/plugin/herdr-plugin.toml
  # manifest 里 command 用 $out 绝对路径（herdr 对绝对路径不做 cwd join）。
  postInstall = ''
    mkdir -p "$out/plugin"
    cat > "$out/plugin/herdr-plugin.toml" <<EOF
    id = "herdr-focus-notify"
    name = "Herdr Focus Notify"
    version = "0.8.0"
    min_herdr_version = "0.7.5"
    description = "Clickable desktop notifications that focus the relevant Herdr agent pane."
    platforms = ["macos"]

    [[startup]]
    command = ["$out/bin/herdr-focus-notify", "--cleanup"]

    [[actions]]
    id = "test"
    title = "Send test focus notification"
    command = ["$out/bin/herdr-focus-notify", "--test"]

    [[actions]]
    id = "clear-terminal-bindings"
    title = "Clear saved terminal bindings"
    command = ["$out/bin/herdr-focus-notify", "--clear-terminal-bindings"]

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
