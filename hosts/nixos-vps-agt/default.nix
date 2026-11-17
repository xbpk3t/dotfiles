{
  config,
  lib,
  globals,
  hostMeta,
  mail,
  pkgs,
  ...
}:
let
  inherit (globals.networking) nameservers;
  linuxFonts = (import ../../modules/fonts.nix { inherit pkgs; }).linux;
in
{
  imports = [ ../_base/nixos-vps ];

  modules = {
    kernel.sysctl.hardware = {
      cpuCores = 4;
      memGiB = 4;
      bwMbps = 6;
      rttMs = 30;
    };

    networking = {
      tailscale.derper = {
        enable = true;
        # 短域名：nva = nixos-vps-agt；域名里不体现 derp。
        domain = "nva.lucc.dev";
        acmeEmail = mail;
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
