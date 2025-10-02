{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.sing-box;

  # 订阅更新脚本
  updateConfig = pkgs.writeShellApplication {
    name = "update-singbox-config";
    runtimeInputs = with pkgs; [ curl jq ];
    text = ''
      set -euo pipefail

      config_dir="/etc/sing-box"
      subscription_url="${cfg.subscription.url}"

      echo "正在更新 sing-box 配置..."

      # 创建配置目录
      mkdir -p "$config_dir"

      # 备份当前配置
      if [ -f "$config_dir/config.json" ]; then
        cp "$config_dir/config.json" "$config_dir/config.json.backup"
      fi

      # 下载并转换配置
      echo "从订阅链接下载配置..."
      curl -L "$subscription_url" \
        -H "User-Agent: sing-box/${cfg.package.version}" \
        -o "$config_dir/config.json"

      # 验证配置文件
      if ! ${cfg.package}/bin/sing-box check -c "$config_dir/config.json"; then
        echo "配置文件验证失败，恢复备份"
        if [ -f "$config_dir/config.json.backup" ]; then
          mv "$config_dir/config.json.backup" "$config_dir/config.json"
        fi
        exit 1
      fi

      echo "配置更新成功，重启 sing-box 服务..."
      systemctl restart sing-box

      # 清理备份文件
      if [ -f "$config_dir/config.json.backup" ]; then
        rm "$config_dir/config.json.backup"
      fi

      echo "sing-box 配置更新完成"
    '';
  };

in {
  options.services.sing-box = {
    subscription = {
      url = mkOption {
        type = types.str;
        description = "订阅链接 URL";
      };

      autoUpdate = mkOption {
        type = types.bool;
        default = true;
        description = "是否自动更新订阅";
      };

      updateInterval = mkOption {
        type = types.str;
        default = "6h";
        description = "自动更新间隔 (systemd 格式)";
      };
    };

    setEnvironment = mkOption {
      type = types.bool;
      default = true;
      description = "是否设置系统代理环境变量";
    };
  };

  config = mkIf cfg.enable {
    # 基础配置 - 使用官方模块
    services.sing-box = {
      # 基础设置
      package = pkgs.sing-box;

      # 默认配置
      settings = {
        log = {
          level = "info";
          timestamp = true;
        };

        dns = {
          servers = [
            {
              tag = "cloudflare";
              address = "https://1.1.1.1/dns-query";
              detour = "proxy";
            }
            {
              tag = "local";
              address = "223.5.5.5";
              detour = "direct";
            }
          ];
          rules = [
            {
              outbound = ["any"];
              server = "local";
            }
            {
              geosite = ["cn"];
              server = "local";
            }
          ];
          final = "cloudflare";
        };

        inbounds = [
          {
            type = "mixed";
            tag = "mixed-in";
            listen = "0.0.0.0";
            listen_port = 1080;
          }
          {
            type = "tproxy";
            tag = "tproxy-in";
            listen = "0.0.0.0";
            listen_port = 1081;
            tcp_fast_open = true;
            udp_fragment = true;
          }
        ];

        outbounds = [
          {
            type = "direct";
            tag = "direct";
          }
          {
            type = "block";
            tag = "block";
          }
        ];

        route = {
          rules = [
            {
              geosite = ["cn"];
              outbound = "direct";
            }
            {
              geoip = ["private"];
              outbound = "direct";
            }
            {
              geoip = ["cn"];
              outbound = "direct";
            }
          ];
          final = "proxy";
          auto_detect_interface = true;
        };
      };
    };

    # 自动更新服务
    systemd.services.sing-box-update = mkIf cfg.subscription.autoUpdate {
      description = "更新 sing-box 订阅配置";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${updateConfig}/bin/update-singbox-config";
        User = "root";
      };
    };

    systemd.timers.sing-box-update = mkIf cfg.subscription.autoUpdate {
      description = "定时更新 sing-box 订阅";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.subscription.updateInterval;
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
    };

    # 环境变量
    environment.sessionVariables = mkIf cfg.setEnvironment {
      HTTP_PROXY = "http://127.0.0.1:1080";
      HTTPS_PROXY = "http://127.0.0.1:1080";
      ALL_PROXY = "http://127.0.0.1:1080";
      http_proxy = "http://127.0.0.1:1080";
      https_proxy = "http://127.0.0.1:1080";
      all_proxy = "http://127.0.0.1:1080";
      NO_PROXY = "localhost,127.0.0.1,::1";
      no_proxy = "localhost,127.0.0.1,::1";
    };

    # 系统包
    environment.systemPackages = with pkgs; [
      cfg.package
      updateConfig
    ];
  };
}