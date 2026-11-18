{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.AI.opencli-browser;
  display = ":99";
  chromiumFlags = [
    "--user-data-dir=${config.home.homeDirectory}/.local/share/chromium-agt"
    "--load-extension=${pkgs.opencli-extension}"
    "--disable-extensions-except=${pkgs.opencli-extension}"
    "--no-first-run"
    "--no-default-browser-check"
    # 无 keyring 的 headless VPS：登录态保存在 profile 内，不依赖 gnome-keyring。
    "--password-store=basic"
    # Chrome 走 mihomo mixed-port；localhost/tailnet/私网绕过。
    "--proxy-server=http://127.0.0.1:7890"
    "--proxy-bypass-list=localhost;127.0.0.1;::1;100.64.0.0/10;10.0.0.0/8;192.168.0.0/16;198.18.0.0/16"
    "--disable-gpu"
    "--disable-dev-shm-usage"
    "--window-size=1920,1080"
    "--window-position=0,0"
    "about:blank"
  ];

  mkUserService = description: extra: {
    Unit = {
      Description = description;
    }
    // (extra.Unit or { });
    Service = {
      Restart = "on-failure";
      RestartSec = 5;
    }
    // (extra.Service or { });
    Install = {
      WantedBy = [ "default.target" ];
    }
    // (extra.Install or { });
  };
in
{
  options.modules.AI.opencli-browser = {
    enable = lib.mkEnableOption ''
      OpenCLI headed Chromium runtime: Xvfb + openbox + Chromium + Browser Bridge
      extension + x11vnc. 用于 headless VPS 上的已登录站点自动化。
    '';

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        x11vnc bind address. Set to the tailnet IP to connect from other
        tailnet devices (macOS Screen Sharing: vnc://<ip>:5900).
      '';
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Start Chromium with the user session. Set false to start it on demand
        with `systemctl --user start chromium-agent`, saving memory when idle.
      '';
    };

    chromiumMemoryHigh = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional systemd MemoryHigh for chromium-agent (e.g. \"700M\").";
    };

    chromiumMemoryMax = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional systemd MemoryMax for chromium-agent (e.g. \"1200M\").";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      chromium
      # opencli CLI 由 pnpm 安装，运行时需要 node；dagu 的 wiki-digest 也依赖它。
      nodejs_24
      x11vnc
    ];

    systemd.user.services = {
      xvfb = mkUserService "Xvfb virtual display ${display}" {
        Service.ExecStart = "${pkgs.xvfb}/bin/Xvfb ${display} -screen 0 1920x1080x24 -nolisten tcp";
      };

      openbox = mkUserService "Openbox window manager for Xvfb" {
        Unit = {
          After = [ "xvfb.service" ];
          Requires = [ "xvfb.service" ];
          PartOf = [ "xvfb.service" ];
        };
        Service = {
          ExecStart = "${pkgs.openbox}/bin/openbox";
          Environment = [ "DISPLAY=${display}" ];
        };
      };

      chromium-agent = mkUserService "Headed Chromium for opencli Browser Bridge" {
        Unit = {
          After = [
            "xvfb.service"
            "openbox.service"
          ];
          Requires = [ "xvfb.service" ];
          PartOf = [ "xvfb.service" ];
          # 10s 重启间隔正好落在 systemd 默认 10s start-limit 窗口外；
          # 显式放宽窗口，避免 MemoryMax 触发后无限 kill/restart。
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        Install.WantedBy = if cfg.autoStart then [ "default.target" ] else [ ];
        Service = {
          ExecStart = "${pkgs.chromium}/bin/chromium ${lib.escapeShellArgs chromiumFlags}";
          Environment = [ "DISPLAY=${display}" ];
          # 浏览器退出（例如最后一个窗口关闭）后需要拉起来。
          Restart = "always";
          RestartSec = 10;
        }
        // lib.optionalAttrs (cfg.chromiumMemoryHigh != null) {
          MemoryHigh = cfg.chromiumMemoryHigh;
        }
        // lib.optionalAttrs (cfg.chromiumMemoryMax != null) {
          MemoryMax = cfg.chromiumMemoryMax;
        };
      };

      x11vnc = mkUserService "x11vnc for Xvfb ${display} (${cfg.bindAddress})" {
        Unit = {
          After = [ "xvfb.service" ];
          Requires = [ "xvfb.service" ];
          PartOf = [ "xvfb.service" ];
        };
        Service = {
          ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display ${display} -listen ${cfg.bindAddress} -nopw -forever -shared -rfbport 5900";
          RestartSec = 10;
        };
      };
    };
  };
}
