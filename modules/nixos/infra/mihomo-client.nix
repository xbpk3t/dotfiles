{
  config,
  pkgs,
  lib,
  mylib,
  ...
}:
with lib;
let
  cfg = config.modules.networking.mihomo-client;
  client = import ../../../lib/mihomo/client-config.nix {
    inherit
      config
      mylib
      lib
      pkgs
      ;
    inherit (cfg) tunExcludeUids extraRules;
    selfProviderTemplateName = "mihomo-self-provider.yaml";
  };
in
{
  options.modules.networking.mihomo-client = {
    enable = mkEnableOption "mihomo proxy service";

    tunExcludeUids = mkOption {
      type = types.listOf types.ints.unsigned;
      default = [ ];
      description = "UIDs excluded from mihomo TUN auto-route (Linux only).";
    };

    extraRules = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "DOMAIN-SUFFIX,zhihu.com,DIRECT" ];
      description = ''
        Extra mihomo rules inserted before GEOIP,CN,DIRECT and MATCH,Manual.
        Use this for per-host/per-role policy differences. The insertion point
        matters: domain rules must match before IP-based GEOIP fallback.
      '';
    };
  };

  config = mkIf cfg.enable {
    # TUN 的返回包从 Meta 进入 INPUT；NixOS firewall 不信任该接口会 DROP SYN-ACK，
    # 表现为 direct curl/进程超时，而 127.0.0.1:7890 代理正常。
    networking.firewall.trustedInterfaces = [ "Meta" ];

    # Why 静态 mihomo user：
    # 1. services.mihomo 默认开 DynamicUser，每次重启 UID 变化；
    # 2. 我们的 self provider 走 /run/secrets/rendered/，由 sops-nix 渲染，
    #    rendered 文件需要显式 owner（DynamicUser 没法在生成 sops 模板之前
    #    确定 UID）；
    # 3. 与 singbox-server 保持一致——那边因为要持有 ACME 证书 group
    #    也走了静态 user，复用同一套 user/group 简化运维。
    users.users.mihomo = {
      isSystemUser = true;
      group = "mihomo";
    };
    users.groups.mihomo = { };

    # sops 默认 owner=root mode=0400，DynamicUser 或静态非 root 都读不到。
    # 显式声明 owner+group+mode 让模板对 mihomo 用户可读。group 0440 而非
    # owner 0400 是为了将来 zashboard UI 如果以普通用户身份 reload 也能读。
    sops.templates."mihomo-client.yaml" = {
      content = client.templatesContent;
      owner = "mihomo";
      group = "mihomo";
      mode = "0440";
    };
    sops.templates."mihomo-self-provider.yaml" = {
      content = client.selfProviderContent;
      owner = "mihomo";
      group = "mihomo";
      mode = "0440";
    };

    services.mihomo = {
      enable = true;
      package = pkgs.mihomo;
      configFile = config.sops.templates."mihomo-client.yaml".path;
      tunMode = true;
    };

    # self provider 已在构建时转为 YAML 且使用绝对路径，无需拷贝。
    # services.mihomo 默认 WorkingDirectory 是 /var/lib/mihomo
    systemd.services.mihomo = {
      # 只有 host 显式启用 systemd-networkd 时才绑定；否则（dhcpcd/NetworkManager）
      # 绑定一个不存在的 unit 会让 mihomo 永远起不来。
      after = lib.optionals config.networking.useNetworkd [ "systemd-networkd.service" ] ++ [
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      partOf = lib.optionals config.networking.useNetworkd [ "systemd-networkd.service" ];
      bindsTo = lib.optionals config.networking.useNetworkd [ "systemd-networkd.service" ];
      serviceConfig = {
        # 关掉 DynamicUser，与上面的静态 user 配套
        DynamicUser = lib.mkForce false;
        User = "mihomo";
        Group = "mihomo";
        # nixpkgs 的 ExecStart 硬编码 -d /var/lib/private/mihomo（DynamicUser 语义）。
        # 这里用静态 user + StateDirectory=mihomo，必须把数据目录对齐 /var/lib/mihomo，
        # 否则 provider 的 /var/lib/mihomo/providers/*.yaml 会落在 SAFE_PATHS 之外。
        ExecStart = lib.mkForce "${pkgs.mihomo}/bin/mihomo -d /var/lib/mihomo -f \${CREDENTIALS_DIRECTORY}/config.yaml";
        # mihomo 默认只允许 homedir 和 SAFE_PATHS 下的路径作为 external-ui /
        # file provider 源。把 zashboard（UI）、sops 渲染目录和 state dir 都加进来。
        Environment = "SAFE_PATHS=${pkgs.zashboard}:/run/secrets/rendered:/var/lib/mihomo";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /var/lib/mihomo/providers"
          # GEOIP,CN 规则需要 Country.mmdb；用 nixpkgs 的 DB-IP 数据（随 flake.lock 月度更新），
          # 避免 mihomo 启动时联网下载（VPS 还没代理）。
          "${pkgs.coreutils}/bin/install -Dm644 ${pkgs.dbip-country-lite.mmdb} /var/lib/mihomo/Country.mmdb"
        ];
      };
    };

    # DNS 防污染
    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNS = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        DNSOverTLS = "yes";
        FallbackDNS = mkDefault config.networking.nameservers;
      };
    };
  };
}
