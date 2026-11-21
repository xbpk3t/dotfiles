{
  config,
  lib,
  globals,
  mail,
  mylib,
  pkgs,
  ...
}:
let
  inherit (globals.networking) nameservers;
  linuxFonts = (import ../../../modules/fonts.nix { inherit pkgs; }).linux;
  # PA 的 tailnet IP 来自 fleet registry（hosts/hm/lightvela/meta.nix）。
  hmPaIp = mylib.fleet.nodes."hm-lightvela".tailscale.ip;
in
{
  imports = [ ../default.nix ];

  modules = {
    kernel.sysctl.hardware = {
      cpuCores = 4;
      memGiB = 4;
      bwMbps = 6;
      rttMs = 30;
    };

    # 4G agent 当前没有容器；Docker 守护进程常驻约 120M，agt 上关闭。
    kernel.vm.docker.enable = false;

    networking = {
      tailscale = {
        derper = {
          enable = true;
          # 短域名 nva = nixos-vps-agt；域名事实在 hosts/nixos-vps/agt/meta.nix。
          acmeEmail = mail;
        };
        # Mac（对称 NAT）↔ hermes 打洞失败后，用 agt（上海）做低延迟 peer relay，
        # 避免回退到绕美国的 DERP(lax/sfo)。使用侧授权见
        # infra/stacks/homelab/tailscale/tailnet/terranix.nix 的 grants（tailscale.com/cap/relay）。
        peerRelay.enable = true;
      };
      mihomo-client = {
        enable = true;
        # derper 的 STUN 回包是 wildcard UDP，源地址选择会被 mihomo TUN 接管；
        # 把 derper 的 UID 排除出 auto-route。
        tunExcludeUids = [ config.users.users.derper.uid ];
      };
    };

    infra.healthchecks = {
      enable = true;
      urlFile = config.sops.secrets.HEALTHCHECKS_VPS_AGT.path;
    };
    # 稳定 UUID：`uuidgen` 生成一次后固定，避免 hostname/FQDN 变化导致重复注册。
    infra.nezha.agent.uuid = "5b8a9ab4-6ed8-4e5d-9c45-03425b6b4644";
  };

  # hm PA 的本地 build 默认经 agt mihomo 代理拉 GitHub
  # （hosts/_base/hm/ansible/group_vars/hm.yml 的 hm_build_network=proxy）。
  # mihomo 已 allow-lan + bind "*"，但防火墙只信任 Meta/lo；不放行
  # tailscale0 会让 PA → agt:7890 的 SYN 被丢弃。
  #
  # 只放行 PA（hermes-wb，fleet 节点 hm-lightvela）。不要用
  # interfaces.tailscale0.allowedTCPPorts：它会把 7890 开给整个 tailnet，
  # 而这个代理没有认证。以后 Mac/手机也要用的话，在这里追加源地址。
  networking.firewall.extraCommands = lib.mkIf (config.networking.firewall.backend == "iptables") ''
    iptables -w -A nixos-fw -i tailscale0 -s ${hmPaIp} -p tcp --dport 7890 -j nixos-fw-accept
  '';
  networking.firewall.extraInputRules = lib.mkIf (config.networking.firewall.backend == "nftables") ''
    iifname "tailscale0" ip saddr ${hmPaIp} tcp dport 7890 accept
  '';

  services = {
    # 上海 VPS 上 1.1.1.1/8.8.8.8 的 DoT 不可达；改用国内 DNS + 明文 53，
    # 让 mihomo TUN 的 dns-hijack(any:53) 接管解析。
    resolved.settings.Resolve = {
      # globals 里的 IPv6 resolver 在 Shanghai 不可达，只取 IPv4。
      DNS = lib.mkForce (lib.filter (n: !(lib.hasInfix ":" n)) nameservers);
      DNSOverTLS = lib.mkForce "no";
    };

    # 手机 herdr-app 走 Tailscale SSH 直连（无需在手机放私钥）。
    # ACL 已有 autogroup:self 的 ssh 规则；这里只是把 node 的 --ssh 打开。
    tailscale.extraUpFlags = [ "--ssh" ];
  };

  # 本地构建：4G agent 上限制并发，避免 OOM（nix-tools 默认 max-jobs=5）。
  nix.settings = {
    max-jobs = lib.mkForce 1;
    cores = lib.mkForce 1;
  };

  # 本地 build 的内存兜底：nix-daemon 及其 build 子进程都受这个 cgroup 限制。
  # 超限时是 build 失败，而不是整机 OOM；eval 是客户端进程，由 user.slice 上限覆盖。
  systemd.services.nix-daemon.serviceConfig = {
    MemoryHigh = "1200M";
    MemoryMax = "2000M";
    # 构建的 swap 也要有边界；超限时是 build 失败，而不是拖垮整机。
    MemorySwapMax = "1G";
  };

  # 4G agent 机的用户会话硬上限：把 OOM 限制在 user.slice 内，
  # 避免 Chromium/Claude 把内核/系统服务一起拖死。dev(6G) 不继承。
  systemd.slices."user".sliceConfig = {
    MemoryHigh = "2800M";
    MemoryMax = "3200M";
    # 只限 RAM 不够：cgroup 默认可以无限用 swap，溢出会进 zram/磁盘。
    # 2G 让 user.slice 在 swap 侧也有硬边界，earlyoom 仍负责提前 kill。
    MemorySwapMax = "2G";
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

  # 固定 derper UID，供 mihomo exclude-uid 使用；当前自动分配就是 993。
  users.users.derper.uid = 993;

  # Chrome 需要 fontconfig/字体；不要继承 server 的 fonts 关闭策略。
  fonts = {
    fontconfig.enable = true;
    packages = linuxFonts;
  };
}
