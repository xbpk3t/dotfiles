{pkgs, ...}: {
  home.packages = with pkgs; [
    # GUI apps
    # e-book viewer(.epub/.mobi/...)
    # do not support .pdf
    # foliate

    # Browsers
    # chromium is configured via programs.chromium below

    reqable

    # Development
    # vscode is configured in wayland-apps.nix

    # Media
    vlc

    # File managers
    xfce.thunar

    # Terminal emulators
    alacritty
    foot

    # System utilities
    pavucontrol

    # Image viewers
    feh
    imv

    # remote desktop(rdp connect)
    # FIXME 换成 rustdesk + frp + tailscale
    # remmina
    # freerdp # required by remmina
    # my custom hardened packages
  ];

  # allow fontconfig to discover fonts and configurations installed through home.packages
  # Install fonts at system-level, not user-level
  fonts.fontconfig.enable = false;

  # Chromium browser configuration
  programs.chromium = {
    enable = true;
    package = pkgs.chromium;

    # Command line flags
    commandLineArgs = [
      # Enable Wayland support
      "--enable-features=UseOzonePlatform"
      "--ozone-platform=wayland"

      # Performance
      "--enable-gpu-rasterization"
      "--enable-zero-copy"

      # Privacy
      "--disable-background-networking"
      "--disable-sync"

      # UI
      "--force-dark-mode"
    ];

    # Extensions (using extension IDs from Chrome Web Store)
    extensions = [
      # uBlock Origin
      {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";}

      # Vimium (vim-like navigation)
      {id = "dbepggeogbaibhgnhhndojpepiihcmeb";}

      # Dark Reader
      {id = "eimadpbcbfnmbkopoojfekhnkhdbieeh";}

      # JSON Viewer
      {id = "gbmdgpbipfallnflgajpaliibnhdgobh";}
    ];
  };
}
