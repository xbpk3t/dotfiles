# 跨平台字体包清单
#
# cross:  两端都安装的核心字体
# linux:  NixOS 额外安装的字体（含 cross）
#
# macOS（nix-darwin）上用 fonts.packages 装到 /Library/Fonts/Nix Fonts，
# Linux（NixOS）上用 fonts.packages 系统级安装。
{
  pkgs,
}:
let
  shared = with pkgs; [
    # ── 主 terminal font ────────────────────────────────────
    # JetBrainsMono + Nerd Font 图标，配合 Ghostty 使用。
    nerd-fonts.jetbrains-mono

    # ── 备选 terminal font ──────────────────────────────────
    nerd-fonts.fira-code

    # ── 中文黑体 ────────────────────────────────────────────
    # 霞鹜新黑体，LXGW WenKai 的姊妹项目，适合屏幕显示。
    # Linux 上无 PingFang 时作为 UI 中文字体，macOS 上当备选。
    lxgw-neoxihei
  ];

  linuxOnly = with pkgs; [
    source-serif-pro
    source-sans-pro
    inter-nerdfont
    noto-fonts-color-emoji
    liberation_ttf
    dejavu_fonts
  ];
in
{
  # 跨平台最小集（cross-platform subset）
  cross = shared;

  # NixOS 全量（Linux-only）
  linux = shared ++ linuxOnly;
}
