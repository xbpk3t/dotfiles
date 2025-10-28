{pkgs, ...}: {
  # Linux Only Packages, not available on Darwin
  home.packages = with pkgs; [
    # misc

    libnotify
    wireguard-tools # manage wireguard vpn manually, via wg-quick

    virt-viewer # vnc connect to VM, used by kubevirt
  ];

  # auto mount usb drives
  services = {
    udiskie.enable = true;
    # syncthing.enable = true;
  };

  # https://mynixos.com/home-manager/options/services.mako
  # notify-send
  services.mako = {
    enable = true;
    #      backgroundColor = "#1e1e2e";
    #      textColor = "#cdd6f4";
    #      borderColor = "#89b4fa";
    #      borderRadius = 8;

    settings = {
      #      anchor = "top-right";

      "actionable=true" = {
        anchor = "top-left";
      };
      actions = true;
      anchor = "top-right";
      icons = true;
      ignore-timeout = false;
      markup = true;

      default-timeout = 3000;
      #      ignore-timeout = 1;

      # keep notifications visible even for fullscreen windows
      # 保证在fullscreen模式下，也能看到弹窗
      layer = "overlay";
      #              "mode=${mode}".invisible = 1;
      "app-name=Countdown" = {
        width = 120;
        height = 48;
        margin = 4;
        padding = 4;
        max-icon-size = 0;
        border-size = 0;
        markup = true;
        format = "<span font='Sans 20' weight='bold'>%s</span>";
        text-alignment = "center";
        font = "Sans 16";
      };
    };
  };
}
