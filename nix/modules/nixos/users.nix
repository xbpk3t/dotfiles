# NixOS user configuration
{ username, ... }:

{
  # User configuration for NixOS
  users = {
    # Allow mutable users (for compatibility)
    mutableUsers = true;

    users = {
      # Main user
      ${username} = {
        isNormalUser = true;
        home = "/home/${username}";
        description = username;
        extraGroups = [
          "wheel"      # sudo access
          "networkmanager"
          "docker"     # for podman docker compatibility
          "systemd-journal"
        ];
        shell = "/run/current-system/sw/bin/zsh";
      };

      # Ops user (from ansible disk.yml)
      ops = {
        isNormalUser = true;
        home = "/home/ops";
        description = "Operations user";
        group = "ops";
        extraGroups = [ "wheel" ];
        shell = "/run/current-system/sw/bin/bash";
      };

      # Root user configuration
      root = {
        # SSH key will be configured per-host
        openssh.authorizedKeys.keys = [
          # Add SSH keys here or configure per-host
        ];
      };
    };

    # Groups
    groups = {
      ops = {};
    };
  };

  # Enable sudo for wheel group
  security.sudo.wheelNeedsPassword = false;
}
