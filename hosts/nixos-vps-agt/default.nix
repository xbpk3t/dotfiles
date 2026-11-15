{
  config,
  lib,
  globals,
  hostMeta,
  mylib,
  pkgs,
  userMeta,
  ...
}:
let
  inherit (globals.networking) nameservers;
  linuxFonts = (import ../../modules/fonts.nix { inherit pkgs; }).linux;
in
{
  imports = [ ../_base/nixos-vps ];

  modules.networking.tailscale.derper = {
    enable = true;
    domain = hostMeta.tailscale.derpDomain;
    inherit (hostMeta) acmeEmail;
  };

  services = {
    # 上海 VPS 上 1.1.1.1/8.8.8.8 的 DoT 不可达；改用国内 DNS + 明文 53，
    # 让 mihomo TUN 的 dns-hijack(any:53) 接管解析。
    resolved.settings.Resolve = {
      # globals 里的 IPv6 resolver 在 Shanghai 不可达，只取 IPv4。
      DNS = lib.mkForce (lib.filter (n: !(lib.hasInfix ":" n)) nameservers);
      DNSOverTLS = lib.mkForce "no";
    };

    # docs-images 共享：Mac 通过 Tailscale 用 NFSv4 挂载（macOS 自带客户端 + LaunchDaemon 自动重挂）。
    # 只允许 macos-ws 的 tailnet IP；all_squash 把 Mac 的 uid 映射到本机 luck(1000)，
    # 这样 Finder 里保存的截图/新图在 VPS 上也归 luck 所有。
    # macOS 的 NFS 客户端只支持 v4.0，且默认用非保留端口；所以额外开 vers4.0 和 insecure。
    nfs = {
      server = {
        enable = true;
        exports = ''
          /home/${userMeta.username}/Desktop/docs-images ${
            mylib.inventory."macos-ws"."macos-ws".ssh.host
          }/32(rw,all_squash,anonuid=1000,anongid=100,no_subtree_check,fsid=0,insecure)
        '';
      };
      settings.nfsd."vers4.0" = "y";
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

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 2049 ];

  # 固定 derper UID，供 mihomo exclude-uid 使用；当前自动分配就是 993。
  users.users.derper.uid = 993;

  modules.networking.mihomo-client = {
    enable = true;
    # derper 的 STUN 回包是 wildcard UDP，源地址选择会被 mihomo TUN 接管；
    # 把 derper 的 UID 排除出 auto-route。
    tunExcludeUids = [ config.users.users.derper.uid ];
  };

  # Chrome 需要 fontconfig/字体；不要继承 server 的 fonts 关闭策略。
  fonts = {
    fontconfig.enable = true;
    packages = linuxFonts;
  };
}
