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
    "--disable-gpu"
    "--disable-dev-shm-usage"
    "--window-size=1920,1080"
    "--window-position=0,0"
    "about:blank"
  ];

  mkUserService = description: extra: {
    Unit = {
      inherit description;
    }
    // (extra.Unit or { });
    Service = {
      Restart = "on-failure";
      RestartSec = 5;
    }
    // (extra.Service or { });
    Install.WantedBy = [ "default.target" ];
  };
in
{
  options.modules.AI.opencli-browser.enable = lib.mkEnableOption ''
    OpenCLI headed Chromium runtime: Xvfb + openbox + Chromium + Browser Bridge
    extension + localhost x11vnc. 用于 headless VPS 上的已登录站点自动化。
  '';

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      chromium
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
        };
        Service = {
          ExecStart = "${pkgs.chromium}/bin/chromium ${lib.escapeShellArgs chromiumFlags}";
          Environment = [ "DISPLAY=${display}" ];
          # 浏览器退出（例如最后一个窗口关闭）后需要拉起来。
          Restart = "always";
          RestartSec = 10;
        };
      };

      x11vnc = mkUserService "x11vnc for Xvfb ${display} (localhost only)" {
        Unit = {
          After = [ "xvfb.service" ];
          Requires = [ "xvfb.service" ];
          PartOf = [ "xvfb.service" ];
        };
        Service = {
          ExecStart = "${pkgs.x11vnc}/bin/x11vnc -display ${display} -localhost -nopw -forever -shared -rfbport 5900";
          RestartSec = 10;
        };
      };
    };
  };
}
