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
  # TODO(volces): devIp 及下面两条 7890 放行只为 AxonHub 的 volces 渠道；
  # 停用 volces 后，连同 tailnet ACL 里 dev → agt:7890 的 grant 一起删除。
  # dev 上的 AxonHub 需要访问只有国内可达的 volces ark 端点，复用 agt mihomo。
  devIp = mylib.fleet.nodes."nixos-vps-dev".tailscale.ip;
  # Mac 的 tailnet IP；只用于 CloudCLI UI（3001）。5900/x11vnc 已随
  # opencli-browser B 方案移除。
  macIp = mylib.fleet.nodes."macos-ws".tailscale.ip;
in
{
  imports = [
    ../default.nix
    ../../../secrets/default.nix
  ];

  modules = {
    # VM 没有硬件 watchdog；softdog（见下方 boot.kernelModules）提供
    # /dev/watchdog 后，这里放宽 systemd 的喂狗超时：默认 15s 对 4G
    # 重载机太激进，60s 兼顾兜底与避免正常抖动误重启。
    systemd.manager.watchdog.runtimeSec = "60s";

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
  # 只放行 PA（hermes-wb，fleet 节点 hm-lightvela）和 dev（AxonHub 的
  # volces 渠道）。不要用 interfaces.tailscale0.allowedTCPPorts：它会把
  # 7890 开给整个 tailnet，而这个代理没有认证。Mac 需要 CloudCLI UI
  # （3001），按源地址单独放行；5900/x11vnc 已随 B 方案移除。
  # 注意：tailnet ACL 只管 tailnet 层，主机 nftables 仍需这条 accept。
  networking.firewall.extraCommands = lib.mkIf (config.networking.firewall.backend == "iptables") ''
    iptables -w -A nixos-fw -i tailscale0 -s ${hmPaIp} -p tcp --dport 7890 -j nixos-fw-accept
    iptables -w -A nixos-fw -i tailscale0 -s ${devIp} -p tcp --dport 7890 -j nixos-fw-accept
    iptables -w -A nixos-fw -i tailscale0 -s ${macIp} -p tcp --dport 3001 -j nixos-fw-accept
  '';
  networking.firewall.extraInputRules = lib.mkIf (config.networking.firewall.backend == "nftables") ''
    iifname "tailscale0" ip saddr ${hmPaIp} tcp dport 7890 accept
    iifname "tailscale0" ip saddr ${devIp} tcp dport 7890 accept
    iifname "tailscale0" ip saddr ${macIp} tcp dport 3001 accept
  '';
  # LUC-585：China 客户端 → agt（TLS + kernel TCP）→ dev host Caddy → 服务。
  # agt 只做入口/relay；证书用 security.acme 的 *.lucc.dev 通配符。
  security.acme.certs."lucc.dev" = {
    email = mail;
    dnsProvider = "cloudflare";
    environmentFile = config.sops.secrets.ACME_CF_ENV.path;
    extraDomainNames = [ "*.lucc.dev" ];
    group = "caddy";
    reloadServices = [ "caddy.service" ];
    extraLegoFlags = [ "--dns.propagation.disable-rns" ];
  };

  # 首次启动时 Caddy 不能早于证书；acme-lucc.dev.service 由 security.acme 生成。
  systemd.services.caddy.after = [ "acme-lucc.dev.service" ];
  systemd.services.caddy.wants = [ "acme-lucc.dev.service" ];

  # LUC-585：agt 是中国侧唯一 relay，Caddy 单点必须优先存活。Caddy RSS
  # 约 35M；256M 上限足够反代多个服务，同时限制异常流量拖垮 4G 整机。
  # OOMScoreAdjust 让内核 OOM killer 优先选其他进程；Restart=always
  # 覆盖 nixpkgs caddy 模块默认的 on-failure，clean exit 也自动拉起。
  systemd.services.caddy.serviceConfig = {
    MemoryHigh = "192M";
    MemoryMax = "256M";
    OOMScoreAdjust = -500;
    Restart = lib.mkForce "always";
  };

  # 只开 tailscale0 的 80/443；公网 80/443 由默认 firewall 关闭。
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    80
    443
  ];

  services = {
    caddy = {
      enable = true;
      openFirewall = false;
      configFile = pkgs.writeText "Caddyfile" ''
        llm.lucc.dev, rsshub.lucc.dev, as.lucc.dev {
          tls /var/lib/acme/lucc.dev/fullchain.pem /var/lib/acme/lucc.dev/key.pem
          @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
          handle @tailnet {
            reverse_proxy http://${mylib.fleet.nodes."nixos-vps-dev".tailscale.ip}:8080
          }
          respond 403
        }

        :80 {
          @tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48
          handle @tailnet {
            redir https://{host}{uri}
          }
          respond 403
        }
      '';
    };

    # 上海 VPS 上 1.1.1.1/8.8.8.8 的 DoT 不可达；改用国内 DNS + 明文 53，
    # 让 mihomo TUN 的 dns-hijack(any:53) 接管解析。
    resolved.settings.Resolve = {
      # globals 里的 IPv6 resolver 在 Shanghai 不可达，只取 IPv4。
      DNS = lib.mkForce (lib.filter (n: !(lib.hasInfix ":" n)) nameservers);
      DNSOverTLS = lib.mkForce "no";
    };

    # user.slice 的 MemorySwapMax 上限让全局 swap free 永远 ≥ ~50%，
    # earlyoom 默认「内存和 swap 同时低于阈值」的条件不可能成立
    # （LUC-562：整个 boot 0 次 kill，机器在 reclaim 里假死）。
    # 100 = 去掉 swap 门槛，只按 MemAvailable 触发。
    earlyoom.freeSwapThreshold = 100;

    # Tailscale SSH 已关闭（LUC-556 D 方案）：显式 --ssh=false，因为仅移除
    # flag 不会改 daemon 的持久偏好。所有 SSH 走 OpenSSH over tailnet；
    # deploy-rs 的 root 连接恢复正常，手机改用 SSH key（tag:ws + 22 grant）。
    tailscale.extraSetFlags = [ "--ssh=false" ];
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
    MemoryHigh = "2400M";
    MemoryMax = "2700M";
    # 只限 RAM 不够：cgroup 默认可以无限用 swap，溢出会进 zram/磁盘。
    # 但 swap 用量本身就是 zram 的 RAM 占用（不可回收）：LUC-562 里 2G
    # 上限让 zram 吃掉隐藏内存、全局 MemAvailable 见底时 earlyoom 的
    # swap 门槛又永不成立。收紧到 1G，配合上面的阈值提前 kill。
    MemorySwapMax = "1G";
  };

  # VM 没有硬件 watchdog（boot 日志：Failed to open any watchdog device）。
  # softdog 用内核定时器模拟 /dev/watchdog，systemd Manager 会周期性喂狗；
  # 用户态被内存回收饿死、PID1 也调度不上时，超时后由 softdog 强制重启。
  # 注意它依赖内核定时器，防不了内核彻底锁死；只是本次这种“活着但假死”的兜底。
  boot.kernelModules = [ "softdog" ];

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
