{
  config,
  lib,
  globals,
  hostMeta,
  mylib,
  pkgs,
  userMeta,
  stateVersion,
  ...
}:
let
  inherit (globals.networking) nameservers;
  agentNodes = mylib.inventory.nodesForContainerHost "nixos-agent" hostMeta.hostName;
  agentEnabled = agentNodes != { };
  agentExternalInterface = lib.attrByPath [ "networking" "externalInterface" ] null hostMeta;
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

  documentation = {
    # server 默认关闭大部分文档产物，减少系统包体积与无关输出。
    enable = lib.mkDefault false;
    doc.enable = lib.mkDefault false;
    info.enable = lib.mkDefault false;
    man.enable = lib.mkDefault false;

    # NixOS manual/options 文档在本仓库里本来就倾向关闭；这里再次作为 server profile 明确声明。
    # 关闭 NixOS options 文档生成（options.json）。
    # 这会规避当前 Nix 对 make-options-doc 派生出的 builtins.derivation context 警告。
    nixos.enable = lib.mkDefault false;
  };

  programs.command-not-found.enable = lib.mkDefault false;

  fonts.fontconfig.enable = lib.mkDefault false;

  # VPS 使用 stable package set，但 NixOS module system 仍来自 rolling。
  # rolling 的 all-terminfo 列表可能引用 stable 中已移除的包（例如 termite），
  # 所以服务器只安装实际需要的常用终端 terminfo。
  environment = {
    enableAllTerminfo = lib.mkForce false;
    systemPackages = [
      pkgs.ghostty.terminfo
      pkgs.kitty.terminfo
      pkgs.tmux.terminfo
      pkgs.wezterm.terminfo
      pkgs.alacritty.terminfo
      pkgs.foot.terminfo
    ];
  };

  xdg = {
    # 这些 freedesktop/XDG 组件主要服务桌面环境；在 server 上默认关闭更符合角色语义。
    autostart.enable = lib.mkDefault false;
    icons.enable = lib.mkDefault false;
    menus.enable = lib.mkDefault false;
    mime.enable = lib.mkDefault false;
    sounds.enable = lib.mkDefault false;
  };

  networking = {
    # hostName 由 inventory 注入；这里提供默认值，避免单机调试时为空
    hostName = lib.mkDefault "nixos-vps";
    useDHCP = true;
    inherit nameservers;
    useHostResolvConf = lib.mkForce false;

    # [2026-05-25] nixos-agent 容器使用 privateNetwork（10.233.0.0/24）。
    # 只有 inventory 中归属到当前 VPS 的 agent 节点存在时才开启 NAT，
    # 并限制到目标机确认过的公网出口。
    nat = lib.mkIf agentEnabled (
      {
        enable = true;
        internalInterfaces = [ "ve-nixos-agent" ];
      }
      // lib.optionalAttrs (agentExternalInterface != null) {
        externalInterface = agentExternalInterface;
      }
    );
  };

  assertions = [
    {
      assertion = !agentEnabled || agentExternalInterface != null;
      message = "nixos-agent container host requires hostMeta.networking.externalInterface.";
    }
  ];

  services = {
    resolved = {
      enable = true;
      # NOTE: fallbackDns 已迁移到 settings.Resolve.FallbackDNS
      settings.Resolve.FallbackDNS = nameservers;
    };

    singbox-server.enable = true;
    mihomo-server.enable = false;

    cron = {
      enable = true;
      mailto = "";
      systemCronJobs = [
        "0 3 * * * luck nu /home/luck/.cntr/backup-pgsql.nu axonhub"
      ];
    };
  };

  modules = {
    networking = {
      tailscale = {
        enable = true;
        derper = {
          enable = true;
          acmeEmail = userMeta.mail;
        };
      };
    };

    systemd.manager.watchdog = {
      # VPS 属于典型无人值守场景，默认启用 systemd Manager watchdog 兜底。
      # 若后续某台机器的 hypervisor/watchdog 行为特殊，直接在对应 host 覆写即可。
      enable = true;
    };

    # k3s agent：VPS 统一作为 worker 节点
    extra.k3s = {
      enable = false;
      role = "agent";
      # serverIP 由 inventory 注入，避免多处重复维护
      serverPort = 6443;
    };
  };

  hardware.enableRedistributableFirmware = lib.mkForce false;

  # Disable scheduled upgrades to avoid conflicts with immutable deployments.
  system.autoUpgrade.enable = lib.mkForce false;
  systemd.services."nixos-upgrade".enable = lib.mkForce false;
  systemd.timers."nixos-upgrade".enable = lib.mkForce false;

  # 启用 nixos-container 容器支持（当前仅 nixos-agent 使用）。
  boot.enableContainers = lib.mkIf agentEnabled true;

  # Why: VPS 上的交互入口主要是 SSH。默认 Linger=no 时，第一次 SSH 登录会冷启动
  # `systemd --user`，而 zsh 的 .zshenv 会立刻 source Home Manager 生成的
  # hm-session-vars.sh。这个脚本里的 secret env 会执行
  # `cat ~/.config/sops-nix/secrets/<name>`；如果它早于 user-level sops-nix.service
  # 生成 `/run/user/<uid>/secrets.d/*`，就会偶发 `No such file or directory`。
  #
  # What: 启用 linger 让 luck 的 user manager 在无人登录时也保持可用，语义上接近
  # macOS 的长期 GUI user session：Home Manager 的 sops-nix user service 可以提前生成
  # user secrets，SSH shell 读取 hm-session-vars.sh 时不再和 secret 生成过程竞态。
  #
  # Scope: 只在 VPS role 上开启。workstation/macOS 不依赖 SSH 冷启动 user manager，
  # 不需要把这个生命周期变化推广到全局 NixOS base。
  users.users.${userMeta.username}.linger = true;

  # [2026-05-25] sops-nix age key：宿主机的 keys.txt 只读挂入 nixos-agent 容器。
  # 容器通过 deploy-rs 独立部署，但 sops 解密发生在容器激活阶段（非构建阶段）。
  # 若容器内无 age 私钥，所有 sops secret（GITHUB_TOKEN 等）解密失败。
  # bind mount 让宿主机和容器共用同一份 age key，无需在容器内手动维护。
  containers.nixos-agent = lib.mkIf agentEnabled {
    bindMounts."sops-age-key" = {
      hostPath = "/home/luck/.config/sops/age/keys.txt";
      mountPoint = "/home/luck/.config/sops/age/keys.txt";
      isReadOnly = true;
    };
  };

  system.stateVersion = lib.mkDefault stateVersion;
}
