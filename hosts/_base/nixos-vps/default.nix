{
  config,
  lib,
  globals,
  hostMeta,
  pkgs,
  stateVersion,
  userMeta,
  ...
}:
let
  inherit (globals.networking) nameservers;
  diskDevice = lib.attrByPath [ "disko" "devices" "disk" "vda" "device" ] "/dev/vda" config;
in
{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    efi.efiSysMountPoint = lib.mkForce "/boot/efi";
    grub = {
      enable = true;
      device = diskDevice;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  networking = {
    # hostName 由 inventory 注入；这里提供默认值，避免单机调试时为空。
    hostName = lib.mkDefault (hostMeta.hostName or "nixos-vps");
    useDHCP = true;
    inherit nameservers;
    useHostResolvConf = lib.mkForce false;
  };

  services = {
    resolved = {
      enable = true;
      settings.Resolve.FallbackDNS = nameservers;
    };

    # 角色相关默认值：host 用普通赋值覆盖，不需要 mkForce。
    cron.enable = lib.mkDefault false;
  };

  modules = {
    systemd.manager.watchdog.enable = true;

    kernel = {
      fhs.enable = true;
      journald.enable = true;
      logind.enable = true;
      ntp.enable = true;
      openssh.enable = true;
      security-server.enable = true;
      vm.enable = true;
    };

    # 所有 VPS 角色都加入 tailnet；DERP / exitNode 由各自 host 显式开启。
    networking = {
      tailscale = {
        enable = lib.mkDefault true;
        exitNode = lib.mkDefault false;
      };
      mihomo-client.enable = lib.mkDefault false;
    };

    # 公共 Nix 管理设置；VPS 只保留签名相关差异。
    infra = {
      nix-tools.enable = lib.mkDefault true;
      singbox-server.enable = lib.mkDefault false;
    };
  };

  nix = {
    # deploy-rs 的构建路径可能产生无签名路径；构建机/目标机默认
    # require-sigs=true 会让 deploy 的 home-manager-path 构建失败。
    # 个人可信 fleet，统一关闭签名校验；比给每台机器分发 builder 签名密钥简单。
    settings.require-sigs = false;

    # 不配置远程 builder：deploy-rs 的 remoteBuild=true 让每个节点本地构建。
    # agent 侧用 max-jobs=1/cores=1 控制内存（见 hosts/nixos-vps-agt）。

    # 定期 GC，避免 store 撑满 66G 盘。
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  fonts.fontconfig.enable = lib.mkDefault false;

  programs = {
    command-not-found.enable = lib.mkDefault false;
    nix-ld.enable = lib.mkDefault false;
  };

  # VPS 无固件需求。
  hardware.enableRedistributableFirmware = lib.mkForce false;

  system = {
    autoUpgrade.enable = lib.mkForce false;
    stateVersion = lib.mkDefault stateVersion;
  };

  # 不用 scheduled upgrade，避免和声明式部署冲突。
  systemd = {
    services."nixos-upgrade".enable = lib.mkForce false;
    timers."nixos-upgrade".enable = lib.mkForce false;
  };

  # dagu / Chromium / Xvfb 都是 user service；linger 让它们在无人登录时启动。
  users.users.${userMeta.username}.linger = true;

  # 所有 VPS 角色都是 headless：关闭文档产物。
  documentation = {
    enable = lib.mkDefault false;
    doc.enable = lib.mkDefault false;
    info.enable = lib.mkDefault false;
    man.enable = lib.mkDefault false;

    # 关闭 NixOS options 文档生成（options.json），规避 make-options-doc
    # 派生出的 builtins.derivation context 警告。
    nixos.enable = lib.mkDefault false;
  };

  # rolling 的 all-terminfo 列表可能引用 stable 中已移除的包（例如 termite），
  # 所以只安装实际需要的常用终端 terminfo。
  environment = {
    enableAllTerminfo = lib.mkForce false;
    systemPackages = [
      pkgs.ghostty.terminfo
      pkgs.kitty.terminfo
      pkgs.tmux.terminfo
      pkgs.wezterm.terminfo
      pkgs.foot.terminfo
    ];
  };

  # freedesktop/XDG 组件主要服务桌面环境；headless VPS 关闭。
  xdg = {
    autostart.enable = lib.mkDefault false;
    icons.enable = lib.mkDefault false;
    menus.enable = lib.mkDefault false;
    mime.enable = lib.mkDefault false;
    sounds.enable = lib.mkDefault false;
  };
}
