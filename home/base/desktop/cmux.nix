{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.desktop.cmux;
in
{
  # ─────────────────────────────────────────────────────────────
  # Behavior matrix: ghostty config deployment triggers
  #
  # cmux (libghostty) reads Ghostty config for terminal rendering.
  # Ghostty config is deployed by ghostty.nix when either ghostty
  # or cmux is enabled (macOS only for cmux).
  #
  #   ghostty.enable  cmux.enable  ghostty config deployed?
  #   ──────────────  ───────────  ─────────────────────────────
  #   false           true         yes (triggered by cmux)
  #   true            false        yes (triggered by ghostty)
  #   false           false        no
  #   true            any          yes (Linux: programs.ghostty)
  #   false           any          no  (Linux: cmux isDarwin=false)
  #
  # Ghostty config is written to XDG path (~/.config/ghostty/config)
  # on macOS, same path as Linux. This path is read by both
  # Ghostty.app and cmux via libghostty.
  # ─────────────────────────────────────────────────────────────

  options.modules.desktop.cmux = {
    enable = mkEnableOption "cmux agent cockpit";
  };

  # cmux 目前仅支持 macOS (Darwin)
  config = mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    # 如果你用 nix-darwin + Homebrew 管 cmux，可以在 nix-darwin 里写：
    #
    # homebrew = {
    #   enable = true;
    #   casks = [ "cmux" ];
    # };
    #
    # 如果你已经用 brew install --cask cmux 装了，这里不需要重复装。

    # [2026-05-20] 发现cmux配置本身的处理很不合理（我用nix管理所有配置，但是cmux竟然可以直接修改成功，这个本身就不正常，所以deep dive了一下）
    ## 1、首先要说明cmux分层配置
    ##
    ## cmux 在 macOS 上同时使用两套配置：
    ##   ~/.config/cmux/cmux.json
    ##     由 Nix/home-manager 从 cmux.jsonc 生成，是我希望维护的 source of truth。
    ##   ~/Library/Preferences/com.cmuxterm.app.plist
    ##     由 cmux Settings GUI 写入，是 macOS UserDefaults override。
    ## 实际优先级大致是：GUI override > Nix file > built-in default。也就是说，即使 cmux.json 已经由 Nix 管理，只要某个字段曾经在 GUI 里改过，plist 里的 override 仍然可能继续压过 Nix 文件。
    ##
    ##
    ## 2、修改配置时，为啥推荐参照schema直接同步回nix? 为啥不推荐直接GUI操作？否则会有哪些潜在问题？
    ##
    ## 因为 schema 支持的稳定配置更适合归 Nix 管：可读、可 diff、可回滚、可迁移。
    ## GUI 只适合临时试配置，不适合作为长期配置入口。
    ## 直接用 GUI 改配置的潜在问题是：GUI 会把字段写进 plist override，之后即使修改了 cmux.jsonc，也可能继续被旧的 plist 值压过，导致“Nix 里改了，但 cmux 实际不生效”的配置漂移。
    ## 所以推荐流程是：
    ##   查 schema / docs -> 改 cmux.jsonc -> task nix: -> 重启 cmux 验证（感觉有点像之前对于firefox的处理）
    ## 如果先在 GUI 里试出了满意值，就把对应 schema 字段同步回 cmux.jsonc；窗口状态、sidebar 宽度、layout、临时 UI state、schema 未声明字段，不回流到 Nix。
    ## 如果已经产生 GUI override 漂移，再退出 cmux、备份 plist、删除对应 defaults key、killall cfprefsd，然后重启 cmux，让配置重新回落到 Nix file。
    xdg.configFile."cmux/cmux.json" = {
      force = true;
      text = builtins.readFile ./cmux.jsonc;
    };
  };
}
