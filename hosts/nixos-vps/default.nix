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
  isAgent = hostMeta.role == "agent";
  isServer = !isAgent;
  incusOn = hostMeta.incus.enable or false;
  linuxFonts = (import ../../modules/fonts.nix { inherit pkgs; }).linux;
in
{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  config = lib.mkMerge [
    # ── 共同 VPS 基线 ─────────────────────────────────────────────
    {
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

      services.resolved = {
        enable = true;
        settings.Resolve.FallbackDNS = nameservers;
      };

      modules.systemd.manager.watchdog.enable = true;

      # VPS 无固件需求。
      hardware.enableRedistributableFirmware = lib.mkForce false;

      # 不用 scheduled upgrade，避免和声明式部署冲突。
      system.autoUpgrade.enable = lib.mkForce false;
      systemd.services."nixos-upgrade".enable = lib.mkForce false;
      systemd.timers."nixos-upgrade".enable = lib.mkForce false;

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

      programs.command-not-found.enable = lib.mkDefault false;

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

      system.stateVersion = lib.mkDefault stateVersion;
    }

    # ── Server 角色（dev/svc）：singbox / derper / k3s / Incus ─────
    (lib.mkIf isServer (
      lib.mkMerge [
        {
          fonts.fontconfig.enable = lib.mkDefault false;

          services.cron = {
            enable = true;
            mailto = "";
            systemCronJobs = [
              "0 3 * * * luck nu /home/luck/.cntr/backup-pgsql.nu axonhub"
            ];
          };

          modules = {
            networking.tailscale = {
              enable = true;
              # 多角色：既是 client + derper，又是 exit node（手机翻墙出口）。
              exitNode = true;
              derper = {
                enable = true;
                domain = hostMeta.tailscale.derpDomain;
                inherit (hostMeta) acmeEmail;
              };
            };

            # k3s agent：role 是模块必填项，其余参数由模块默认值和 inventory 覆盖。
            ms.k3s = {
              role = "agent";
            }
            // (hostMeta.k3s or { });

            infra.singbox-server.enable = true;
          };
        }

        # Incus lab：仅 inventory 显式开启的节点。
        (lib.mkIf incusOn {
          virtualisation.incus.enable = true;
          users.users.${userMeta.username}.extraGroups = [ "incus-admin" ];
          networking = {
            nftables.enable = true;
            firewall.trustedInterfaces = [ "incusbr0" ];
          };
        })
      ]
    ))

    # ── Agent 角色（agt）：dagu + headed Chromium，无 singbox/derper/k3s ──
    (lib.mkIf isAgent {
      modules.networking.mihomo-client.enable = true;

      # Chrome 需要 fontconfig/字体；不要继承 server 的 fonts 关闭策略。
      fonts = {
        fontconfig.enable = true;
        packages = linuxFonts;
      };
    })
  ];
}
