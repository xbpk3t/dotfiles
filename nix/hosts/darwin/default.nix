# Darwin host configuration
# This file contains host-specific configurations that should not be shared between different machines
{ username, ... }:

{
  # Host-specific system configuration
  system = {
    # Set the primary user for this specific machine
    primaryUser = username;

    # System defaults specific to this host
    defaults = {
      # Dock settings
      dock = {
        tilesize = 4;
        magnification = false;
        largesize = 32;
        orientation = "left";
        autohide = true;
        autohide-delay = 0.0;
        # Remove all default apps
        persistent-apps = [];
      };

      # Finder settings
      finder = {
        AppleShowAllFiles = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        FXDefaultSearchScope = "SCcf";
        FXPreferredViewStyle = "clmv"; # Default column view
      };

      # Global settings
      NSGlobalDomain = {
        # Time configuration
        AppleICUForce24HourTime = true;
        AppleInterfaceStyle = null; # Dark or null

        # Keyboard settings
        KeyRepeat = 2; # Set to fastest
        InitialKeyRepeat = 15;
        AppleKeyboardUIMode = 3;

        # Finder settings
        AppleShowAllExtensions = true;

        # Trackpad settings
      };

      # Screensaver settings
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;
      };

      # Trackpad settings
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };

    # System state version - this is host-specific and should not be changed after initial installation
    system.stateVersion = 6;
  };

  # Host-specific user configuration
  users.users = {
    # Main user configuration for this specific machine
    ${username} = {
      home = "/Users/${username}";
      description = username;
      shell = "/run/current-system/sw/bin/zsh";
    };

    # Ops user (from ansible disk.yml)
    # Note: Creating users on macOS requires different approach
    ops = {
      home = "/Users/ops";
      description = "Operations user";
      shell = "/bin/bash";
    };
  };

  # Host-specific Nix settings
  nix.settings.trusted-users = [ username ];

  # Import shared and Darwin-specific modules
  imports = [
    ../../modules/darwin
    ../../modules/shared
  ];
}
