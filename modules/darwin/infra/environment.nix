# Darwin 系统级环境配置（全局、跨 shell / daemon / GUI）。
#
# 【职责边界】—— 只放"系统级、不归属单一 client"的部分；已有 coverage 不重复：
#   - environment.shells / pathsToLink      → infra/users.nix（用户壳配置）
#   - environment.shellAliases（tss）       → networking/tailscale-client.nix
#   - environment.systemPackages（singbox） → networking/singbox-client.nix
#
# 【实机/基线依据】本文件每行均经
#   `nix eval .#darwinConfigurations.macos-ws.config.environment.<x>`
#   结合与 NixOS kernel/openssh.nix 基线的对照才落下，不设空壳、不硬塞无效项。
{
  lib,
  ...
}:
{
  # ─── 全局 shell 环境变量 ─────────────────────────────────────────────
  # [environment - MyNixOS](https://mynixos.com/nix-darwin/options/environment)
  #
  # 背景：系统 nix-darwin 默认注入 `EDITOR=nano`（interactive shell 里
  # home-manager 设的却是 hx = 另一源）。两个来源不一致。
  # 处理：强统一到 hx，使 GUI app / daemon / sudo 环境不再回落 nano。
  environment.variables = {
    # 系统级统一编辑器
    EDITOR = lib.mkForce "hx";
    VISUAL = lib.mkForce "hx";
  };

  # ─── terminfo：与 NixOS 基线对齐 ─────────────────────────────────────
  # modules/nixos/kernel/openssh.nix 显式 `environment.enableAllTerminfo = true`
  # 来保证远端/SSH 终端的 terminfo 完整（如 ghostty ssh 连入不退化 vt100）。
  # darwin 侧此前缺这条基线 —— 这里补齐对齐。nix-darwin 默认 false。
  environment.enableAllTerminfo = true;

  # ─── 全局登录/交互 shell init（默认留空，依赖 home-module 的 zshrc/bashrc）──
  # macOS 全局 /etc/zshenv 已由 nix-darwin 默认注入 brew shellenv。
  # 留空即为"不额外注入"，避免与 home.nix 重复；不设空壳干扰。
  # environment.loginShellInit = "";
  # environment.interactiveShellInit = "";
  # environment.shellInit = "";

  # ─── 全局 shell alias（兜底，跨 zsh/bash/fish）────────────────────────
  # per-client alias（tss）已在 tailscale-client.nix；这里目前无跨 shell 强需。
  # environment.shellAliases = { };

  # ─── 全局工具包（非 client 专属、本机任何场景都要）──────────────────
  # 目前无硬性全局新增包（工具多由 home/systemP 提供），留空=当前无补充。
  # environment.systemPackages = [ ];
}
