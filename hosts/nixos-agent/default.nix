{
  lib,
  globals,
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
    # 容器使用私有网桥网络（NAT），由宿主机 nixos-containers 自动分配 IP
  };

  # [2026-05-25] 容器 DNS：boot.isContainer 环境下 resolvconf 会生成 127.0.0.53
  # （systemd-resolved stub），但容器内 resolved 已禁用且网络命名空间隔离无法
  # 访问宿主机 stub。关闭 resolvconf，直接硬写 resolv.conf。
  networking.resolvconf.enable = false;
  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 119.29.29.29
    nameserver 223.5.5.5
    options edns0 trust-ad
  '';

  # 容器首次激活时 /home/luck 可能未创建（user-group.nix 的 isNormalUser 和
  # home-manager 激活脚本的时序不确定），导致 sops-nix 写 ~/.config/systemd 失败。
  # activationScript 在 NixOS switch 期间同步执行（deps 保证在 users 创建后），
  # 比 systemd-tmpfiles（异步 service）更可靠。
  # 注意：chown 不能 -R，sops age keys.txt 通过 bind mount 挂载为只读。
  system.activationScripts.ensureHomeDir = {
    text = ''
      chown luck:users /home/luck
      mkdir -p /home/luck/.config/systemd
      chown luck:users /home/luck/.config /home/luck/.config/systemd
    '';
    deps = ["users" "groups"];
  };

  # [2026-05-25] NixOS 容器通过宿主机 /etc/resolv.conf 解析 DNS，
  # 启用 systemd-resolved 会触发断言失败（"Using host resolv.conf is not supported"）。
  # 容器内 DNS 由宿主机接管，无需额外配置。
  # 基本网络服务
  # services.resolved = {
  #   enable = true;
  #   settings.Resolve.FallbackDNS = nameservers;
  # };

  system.stateVersion = "24.11";
}
