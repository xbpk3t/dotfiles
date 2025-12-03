{
  pkgs,
  config,
  lib,
  ...
}: let
  # 对外域名占位（订阅里 server_name 用；本地验证不跑 ACME/443）
  # FIXME 域名也应从sops获得，这样workstation可以直接在本地拼接（域名、token）获得订阅URL
  # FIXME 在上线该singbox server到DMIT之前，仍需要补充 BBR优化之类的配置。本 nixos-cntr配置也可以看作是最小化可用的nixos minimal. 但是仍需要优化
  domain = "";

  # sing-box 入站端口
  singboxPort = 24443;

  # nginx 对外端口（明文，容器验证用）
  nginxPort = 8020;

  # 运行时生成的密钥存放路径（不进入 Nix store）
  secretPath = "/var/lib/singbox/server-secrets.json";
  nginxTokenConf = "/etc/nginx/subtoken.conf";

  # 客户端订阅文件；nginx 暴露为 /sub
  subPath = "/etc/sub.json";
in {
  ##############################
  # 基础依赖
  ##############################
  environment.systemPackages = with pkgs; [
    sing-box
    util-linux
    gawk

# 已经引入了 home/base/core，所以注释掉
#    jq
#    helix
#    nushell
  ];

  # 确保占位目录存在
  systemd.tmpfiles.rules = [
    "d /var/lib/singbox 0700 root root -"
    "d /var/www/empty 0755 root root -"
  ];

  ##############################
  # 1) 生成服务端密钥（首启一次）
  ##############################
  systemd.services.singbox-generate-secrets = {
    description = "Generate sing-box server secrets (uuid + REALITY keys)";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      set -euo pipefail
      export PATH=${lib.makeBinPath [pkgs.nushell pkgs.sing-box pkgs.util-linux pkgs.coreutils pkgs.gawk pkgs.jq pkgs.findutils pkgs.gnused]}:$PATH
      ${pkgs.nushell}/bin/nu ${./generate-secrets.nu} --secret-path ${secretPath}
    '';
  };

  ##############################
  # 2) 生成订阅 token（首启一次，必须提供 PWGEN_SECRET）
  ##############################
  # 改为用 sops 管理订阅 token，避免明文写仓库
  # secrets/default.nix: singboxToken = mkRootSecret "singbox/token";

  ##############################
  # 3) 渲染服务端配置 + 客户端订阅（引用生成的密钥/token）
  ##############################
  systemd.services.singbox-render-configs = {
    description = "Render sing-box server/client configs (runtime secrets)";
    wantedBy = ["multi-user.target"];
    requires = [
      # secrets + runtime keys must exist before rendering
      "singbox-generate-secrets.service"
    ];
    after = [
      "singbox-generate-secrets.service"
    ];
    unitConfig = {
      # Ensure the decrypted token exists before running, but don't depend on
      # non-existent sops-* services (sops runs in activation, not as a unit).
      ConditionPathExists = config.sops.secrets.singboxToken.path;
    };
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      set -euo pipefail
      export PATH=${lib.makeBinPath [pkgs.nushell pkgs.sing-box pkgs.util-linux pkgs.coreutils pkgs.gawk pkgs.jq pkgs.findutils pkgs.gnused]}:$PATH
      ${pkgs.nushell}/bin/nu ${./render-configs.nu} \
        --secret-path ${secretPath} \
        --token-path ${config.sops.secrets.singboxToken.path} \
        --domain ${domain} \
        --singbox-port ${toString singboxPort} \
        --sub-path ${subPath} \
        --nginx-token-conf ${nginxTokenConf}
    '';
  };

  ##############################
  # 3) sing-box 服务端（使用自生成的 config）
  ##############################
  services.sing-box = {
    enable = true;
    settings = {}; # 配置文件由上面的渲染脚本生成
    package = pkgs.sing-box;
  };

  # 确保 sing-box 在配置生成后再启动
  systemd.services.sing-box = {
    after = [
      "network.target"
      "singbox-render-configs.service"
    ];
    requires = ["singbox-render-configs.service"];
  };

  ##############################
  # 4) nginx 暴露订阅 /sub （Basic Auth）
  ##############################
  services.nginx = {
    enable = true;
    virtualHosts."_" = {
      # 如需启用域名/ACME 再打开：
      # enableACME = true;
      # forceSSL = true;
      listen = [
        {
          addr = "0.0.0.0";
          port = nginxPort;
        }
      ];
      root = "/var/www/empty";

      locations."/sub" = {
        root = "/etc";
        extraConfig = ''
          include ${nginxTokenConf};
          if ($arg_token != $sub_token) { return 401; }
          try_files /sub.json =404;
          default_type application/json;
        '';
      };
    };
  };

  ##############################
  # 5) 防火墙
  ##############################
  networking.firewall.allowedTCPPorts = [
    nginxPort
    singboxPort
  ];
}
