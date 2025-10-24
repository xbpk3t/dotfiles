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
      anchor = "top-right";
      default-timeout = 3000;
      ignore-timeout = 1;
      #              "mode=${mode}".invisible = 1;
    };
  };
}
