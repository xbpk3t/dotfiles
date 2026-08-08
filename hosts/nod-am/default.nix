{
  pkgs,
  lib,
  ...
}:
{
  # why this? 手机本机 Nix 终端环境，作为移动端 SSH client 使用
  # 与 nixos-avf 的区别：
  #   - nixos-avf: Android AVF 虚拟机里刷 NixOS（系统级）
  #   - nod-am: 手机本机 Nix 用户态（proot，非系统级），SSH 客户端定位

  # proot 环境固定 aarch64-linux，避免宿主架构误判
  nixpkgs.hostPlatform = "aarch64-linux";

  # 用户 UID/GID：由 outputs 层从 inventory 注入（见 outputs/.../nod-am.nix）
  # Why: deploy-rs 远程部署会生成错误 uid，必须显式指定（nix-on-droid issue #94）

  # home-manager 层：复用仓库现成 shell 模块，不重复实现
  home-manager = {
    # import 现成的 ssh / zsh / fzf 模块（手机 SSH client 场景）
    sharedModules = [
      (import ../../home/base/kernel/ssh.nix)
      (import ../../home/core/kernel/zsh.nix)
      (import ../../home/core/kernel/fzf.nix)
    ];
    # zsh.nix 依赖 editorMeta specialArg（设置 EDITOR / vim 别名）
    extraSpecialArgs.editorMeta = {
      command = "hx";
      desktopEntry = "Helix.desktop";
    };

    # NOD 特有：atuin 记录 ssh 历史，模糊搜索快速回放
    config = {
      programs.atuin = {
        enable = true;
        settings = {
          sync_frequency = "10m";
          search_mode = "fuzzy";
        };
      };
    };
  };

  # NOD 环境直接暴露的包（对应 environment.packages）
  environment.packages = with pkgs; [
    # 基础工具
    git
    htop
    ripgrep
    tmux

    # 远程管理（SSH client 定位）：deploy-rs / ssh 依赖
    openssh

    # tailscale userspace：让 NOD 内可被 deploy-rs 走 tailscale IP 连到
    # 注意：proot 无内核权限，tailscale 需 userspace 模式（tun=userspace-networking）
    tailscale

    # 现成 zsh 模块用 hx 设定 EDITOR（editorMeta.command）
    helix
  ];

  system.stateVersion = lib.mkDefault "24.05";
}
