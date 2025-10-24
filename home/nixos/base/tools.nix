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
    #      defaultTimeout = 2000;
    #      backgroundColor = "#1e1e2e";
    #      textColor = "#cdd6f4";
    #      borderColor = "#89b4fa";
    #      borderRadius = 8;
  };
}
