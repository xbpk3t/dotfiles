{
  config,
  lib,
  globals,
  hostMeta,
  mylib,
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
  inherit (mylib) inventory;
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

      modules = {
        systemd.manager.watchdog.enable = true;

        # 所有 VPS 角色都加入 tailnet 并跑 DERP；server 角色额外声明 exit node。
        networking.tailscale = {
          enable = true;
          derper = {
            enable = true;
            domain = hostMeta.tailscale.derpDomain;
            inherit (hostMeta) acmeEmail;
          };
        };
      };

      nix = {

        # 远程 builder（nixos-vps-dev）会产出无签名路径；构建机/目标机默认
        # require-sigs=true 会让 deploy 的 home-manager-path 构建失败。
        # 个人可信 fleet，统一关闭签名校验；比给每台机器分发 builder 签名密钥简单。
        settings.require-sigs = false;

        # 下载/构建加速：复用 Mac 上的 numtide / nix-community 缓存，并把大包
        # offload 到 dev VPS（nixos-vps-dev）。builders 由 nix-daemon(root) 使用
        # /root/.ssh/id_ed25519 连接；该公钥需在 dev 的 luck authorized_keys 中。
        settings = {
          inherit (mylib.nixCacheSettings) substituters;
          trusted-public-keys = mylib.nixCacheSettings.trustedPublicKeys;
          trusted-users = [ "@wheel" ];
        };

        distributedBuilds = true;
        buildMachines = [
          {
            hostName = inventory."nixos-vps"."nixos-vps-dev".tailscale.ip;
            sshUser = userMeta.username;
            sshKey = "/root/.ssh/id_ed25519";
            protocol = "ssh-ng";
            system = "x86_64-linux";
            maxJobs = 5;
            supportedFeatures = [
              "nixos-test"
              "benchmark"
              "big-parallel"
              "kvm"
            ];
          }
        ];

        # 定期 GC，避免 store 撑满 66G 盘。
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 14d";
        };

      };

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
            # 多角色：client + derper（公共基线），并作为 exit node（手机翻墙出口）。
            networking.tailscale.exitNode = true;

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

    # ── Agent 角色（agt）：dagu + headed Chromium + Tailscale DERP，无 singbox/k3s ──
    (lib.mkIf isAgent {
      # 上海 VPS 上 1.1.1.1/8.8.8.8 的 DoT 不可达；改用国内 DNS + 明文 53，
      # 让 mihomo TUN 的 dns-hijack(any:53) 接管解析。
      services = {
        resolved.settings.Resolve = {
          # globals 里的 IPv6 resolver 在 Shanghai 不可达，只取 IPv4。
          DNS = lib.mkForce (lib.filter (n: !(lib.hasInfix ":" n)) nameservers);
          DNSOverTLS = lib.mkForce "no";
        };

        # docs-images 共享：Mac 通过 Tailscale 用 NFSv4 挂载（macOS 自带客户端 + LaunchDaemon 自动重挂）。
        # 只允许 macos-ws 的 tailnet IP；all_squash 把 Mac 的 uid 映射到本机 luck(1000)，
        # 这样 Finder 里保存的截图/新图在 VPS 上也归 luck 所有。
        # macOS 的 NFS 客户端只支持 v4.0，且默认用非保留端口；所以额外开 vers4.0 和 insecure。
        nfs.server = {
          enable = true;
          extraNfsdConfig = "vers4.0=y";
          exports = ''
            /home/${userMeta.username}/Desktop/docs-images ${
              inventory."macos-ws"."macos-ws".ssh.host
            }/32(rw,all_squash,anonuid=1000,anongid=100,no_subtree_check,fsid=0,insecure)
          '';
        };

        # 手机 herdr-app 走 Tailscale SSH 直连（无需在手机放私钥）。
        # ACL 已有 autogroup:self 的 ssh 规则；这里只是把 node 的 --ssh 打开。
        tailscale.extraUpFlags = [ "--ssh" ];
      };

      # 官方 Node 的 V8 getter 与 nixpkgs Node 的加固编译不同；dsh 的
      # node-addon-require-builtin 只认官方构建。nix-ld 让官方 Node 能在 NixOS 上跑。
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          stdenv.cc.cc.lib
          libgcc
          glibc
          zlib
          openssl
        ];
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2049 ];

      modules = {
        networking.mihomo-client.enable = true;
      };

      # Chrome 需要 fontconfig/字体；不要继承 server 的 fonts 关闭策略。
      fonts = {
        fontconfig.enable = true;
        packages = linuxFonts;
      };
    })
  ];
}
