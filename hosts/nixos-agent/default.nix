{
  lib,
  globals,
  userMeta,
  ...
}: let
  inherit (globals.networking) nameservers;
in {
  #############################################################
  #
  #  nixos-agent - NixOS Container for ClaudeClaw
  #
  #  运行在 VPS 宿主机上，提供隔离的 agent 环境。
  #  仅包含 Claude Code + MCP + Skills 等 AI 工具链，
  #  不含桌面/GPU/X11 等 workstation 组件。
  #
  #############################################################

  # 标记为 NixOS 容器（轻量，共享宿主机内核）
  boot.isContainer = true;

  # 启用容器优化（禁用引导器、文档、getty 等）
  modules.base.container.enable = true;

  networking = {
    hostName = lib.mkDefault "nixos-agent";
    useDHCP = false;
    nameservers = nameservers;
    # 容器默认使用宿主网络命名空间，无需额外配置
  };

  # 基本网络服务
  services.resolved = {
    enable = true;
    settings.Resolve.FallbackDNS = nameservers;
  };

  # Nix 配置（容器共享宿主机 Nix daemon）
  nix = {
    # 容器内直接使用宿主机的 nix-daemon socket
    settings = {
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-users = [userMeta.username];
    };
  };

  system.stateVersion = "24.11";
}
