{pkgs, ...}: {
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    hyprland = {
      enable = true; # set this so desktop file is created
      withUWSM = false;
    };
    dconf.enable = true;
    seahorse.enable = true;
    fuse.userAllowOther = true;
    mtr.enable = true;
    adb.enable = true;
    hyprlock.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Hyprland systeminfo QT  (Optional)
    #inputs.hyprsysteminfo.packages.${pkgs.system}.default

    #aider-chat # AI in terminal (Optional: Client only)
    #    appimage-run # Needed For AppImage Support
    #    brightnessctl # For Screen Brightness Control
    #    #claude-code # Claude code terminal AI (Optional: Client only)
    #    cliphist # Clipboard manager using rofi menu
    #    cmatrix # Matrix Movie Effect In Terminal
    #    cowsay # Great Fun Terminal Program
    #    discord # Stable client
    #    discord-canary # beta  client
    #    docker-compose # Allows Controlling Docker From A Single File
    #    duf # Utility For Viewing Disk Usage In Terminal
    #    dysk # Disk space util nice formattting
    #    eza # Beautiful ls Replacement
    #    ffmpeg # Terminal Video / Audio Editing
    #    file-roller # Archive Manager
    #    gedit # Simple Graphical Text Editor
    #    #gemini-cli # CLI AI client ONLY (optional)
    #    gimp # Great Photo Editor
    #    glxinfo # needed for inxi diag util
    #    greetd.tuigreet # The Login Manager (Sometimes Referred To As Display Manager)
    #    htop # Simple Terminal Based System Monitor
    #    hyprpicker # Color Picker
    #    eog # For Image Viewing
    #    inxi # CLI System Information Tool
    #    killall # For Killing All Instances Of Programs
    #    libnotify # For Notifications
    #    lm_sensors # Used For Getting Hardware Temps
    #    lolcat # Add Colors To Your Terminal Command Output
    #    lshw # Detailed Hardware Information
    #    mpv # Incredible Video Player
    #    ncdu # Disk Usage Analyzer With Ncurses Interface
    #    nixfmt-rfc-style # Nix Formatter
    #    nwg-displays # configure monitor configs via GUI
    #    onefetch # provides zsaneyos build info on current system
    #    pavucontrol # For Editing Audio Levels & Devices
    #    pciutils # Collection Of Tools For Inspecting PCI Devices
    #    picard # For Changing Music Metadata & Getting Cover Art
    #    pkg-config # Wrapper Script For Allowing Packages To Get Info On Others
    #    playerctl # Allows Changing Media Volume Through Scripts
    #    rhythmbox # audio player
    #    ripgrep # Improved Grep
    #    socat # Needed For Screenshots
    #    unrar # Tool For Handling .rar Files
    #    unzip # Tool For Handling .zip Files
    #    usbutils # Good Tools For USB Devices
    #    uwsm # Universal Wayland Session Manager (optional must be enabled)
    #    v4l-utils # Used For Things Like OBS Virtual Camera
    #    warp-terminal # Terminal with AI support build in
    #    waypaper # Change wallpaper
    #    wget # Tool For Fetching Files With Links
    # ytmdl # Tool For Downloading Audio From YouTube
  ];
}
