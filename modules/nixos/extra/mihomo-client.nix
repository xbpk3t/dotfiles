{
  config,
  pkgs,
  lib,
  mylib,
  ...
}:
with lib; let
  cfg = config.modules.networking.mihomo;
  client = import ../../../lib/mihomo/client-config.nix {
    inherit
      config
      mylib
      lib
      pkgs
      ;
    inherit (cfg) wildUrl;
    selfProviderTemplateName = "mihomo-self-provider.yaml";
  };
in {
  options.modules.networking.mihomo = {
    enable = mkEnableOption "mihomo proxy service";
    wildUrl = mkOption {
      type = lib.types.str;
      default = "http://${mylib.inventory."nixos-vps"."nixos-vps-dev".tailscale.ip}:3001/admin/download/collection/wild?target=ClashMeta";
      description = ''
        Sub-Store wild provider subscription URL。
        默认指向 nixos-vps-dev 的 sub-store（tailscale 内网，admin path 固定 /admin）。
      '';
    };
  };

  config = mkIf cfg.enable {
    # Why 静态 mihomo user：
    # 1. services.mihomo 默认开 DynamicUser，每次重启 UID 变化；
    # 2. 我们的 self provider 走 /run/secrets/rendered/，由 sops-nix 渲染，
    #    rendered 文件需要显式 owner（DynamicUser 没法在生成 sops 模板之前
    #    确定 UID）；
    # 3. 与 modules/nixos/vps/mihomo-server.nix 保持一致——那边因为要持有
    #    ACME 证书 group 也走了静态 user，复用同一套 user/group 简化运维。
    users.users.mihomo = {
      isSystemUser = true;
      group = "mihomo";
    };
    users.groups.mihomo = {};

    # sops 默认 owner=root mode=0400，DynamicUser 或静态非 root 都读不到。
    # 显式声明 owner+group+mode 让模板对 mihomo 用户可读。group 0440 而非
    # owner 0400 是为了将来 metacubexd UI 如果以普通用户身份 reload 也能读。
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
      after = ["systemd-networkd.service" "network-online.target"];
      wants = ["network-online.target"];
      partOf = ["systemd-networkd.service"];
      bindsTo = ["systemd-networkd.service"];
      serviceConfig = {
        # 关掉 DynamicUser，与上面的静态 user 配套
        DynamicUser = lib.mkForce false;
        User = "mihomo";
        Group = "mihomo";
        # mihomo 默认只允许 homedir 和 SAFE_PATHS 下的路径作为 external-ui /
        # file provider 源。把 metacubexd（UI）和 sops 渲染目录都加进来。
        Environment = "SAFE_PATHS=${pkgs.metacubexd}:/run/secrets/rendered";
        ExecStartPre = [
          "${pkgs.coreutils}/bin/mkdir -p /var/lib/mihomo/providers"
        ];
      };
    };

    # DNS 防污染
    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNS = ["1.1.1.1" "8.8.8.8"];
        DNSOverTLS = "yes";
        FallbackDNS = mkDefault config.networking.nameservers;
      };
    };
  };
}
