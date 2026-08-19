# sm 轨 sing-box server（vless-reality）。
#
# 对抗式搜索结论与取舍：
#   - 首选「import nixpkgs services.sing-box 模块」——sm 支持其依赖
#     systemd.packages/utils。但实测 import 后报 `services.dbus` 不存在：
#     sing-box 包自带 unit 经 systemd.packages 处理时引用 dbus 激活，sm 无此 option。
#     → 放弃 import，改用 mihomo 同款成熟模式（sops.templates + 手写 unit）。
#   - secrets 复用 sm sops.nix 已声明的 PROXY_UUID/PRI_KEY/ID（系统 root secret），
#     用 config.sops.placeholder.* 在 sops 模板里引用（运行时渲染，不进 store）。
#   - 只做 vless-reality（Reality 握手用公网站点，无需 ACME 证书/域名）；
#     vmess/hy2/tuic/anytls 需要真实域名证书，SGP 临时机不做。
#
# 这是「服务角色」，走 modules.infra.singbox-server.enable 开关（对齐
# hosts/sm-vps/default.nix 注释），由 hosts/sm-vps 启用。
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.infra.singbox-server;
  port = 8443;
  # 伪装握手目标（Reality 标准做法，选稳定大站）
  handshakeServer = "www.bing.com";
in
{
  _file = ./singbox.nix;

  options.modules.infra.singbox-server = {
    enable = mkEnableOption "sing-box server (vless-reality) on sm";
  };

  config = mkIf cfg.enable {
    # 服务角色仅对非共享机启用（hosts/sm-vps/default.nix 用 mkIf (!isShared) 包住
    # services.*，shared 下不启用）；sops 模块在 shared 下不 import，config.sops.*
    # 不可用——但本 config 块在 enable=false（shared）时整体不求值，安全。
    environment.systemPackages = [ pkgs.sing-box ];

    # sops 模板：sing-box 配置运行时渲染（placeholder → 真实 secret）。
    # 依赖 modules/sm/sops.nix（基线 enable）。输出路径 = template.path。
    sops.templates."sing-box-config.json" = {
      content = builtins.toJSON {
        log.level = "info";

        inbounds = [
          {
            type = "vless";
            tag = "vless-reality";
            listen = "::";
            listen_port = port;

            users = [
              {
                uuid = config.sops.placeholder.PROXY_UUID;
                flow = "xtls-rprx-vision";
              }
            ];

            tls = {
              enabled = true;
              server_name = handshakeServer;

              reality = {
                enabled = true;

                handshake = {
                  server = handshakeServer;
                  server_port = 443;
                };

                private_key = config.sops.placeholder.PROXY_PRI_KEY;
                short_id = [ config.sops.placeholder.PROXY_ID ];
              };
            };
          }
        ];

        outbounds = [
          {
            type = "direct";
            tag = "direct";
          }
        ];

        route.rules = [
          {
            outbound = "direct";
          }
        ];
      };
      owner = "root";
      group = "root";
      mode = "0400";
    };

    # sops 模块在 shared 下不 import（config.sops.* 不存在）；本 config 块仅在
    # cfg.enable（= !isShared 且 hosts 启用）时求值，shared 下整体跳过。
    systemd.services.sing-box = {
      enable = true;
      description = "sing-box server (vless-reality)";
      wantedBy = [ "system-manager.target" ];
      after = [
        "network.target"
        "sops-install-secrets.service"
      ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${
          config.sops.templates."sing-box-config.json".path
        }";
        Restart = "on-failure";
        RestartSec = "10s";
        # 与 sm 其他服务一致的最小加固
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        NoNewPrivileges = true;
      };
    };
  };
}
