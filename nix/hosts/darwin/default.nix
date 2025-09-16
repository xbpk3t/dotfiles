# Darwin host configuration
# This file contains host-specific configurations that should not be shared between different machines
{username, ...}: {
  # System state version - this is host-specific and should not be changed after initial installation
  system.stateVersion = 6;

  # Host-specific user configuration
  users.users = {
    # Main user configuration for this specific machine
    ${username} = {
      home = "/Users/${username}";
      description = username;
      #      shell = "/run/current-system/sw/bin/bash";
      shell = "/etc/profiles/per-user/${username}/bin/bash";
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
  nix.settings.trusted-users = [username];

  # Ensure bash is available in /etc/shells for chsh
  environment.shells = [
    "/etc/profiles/per-user/${username}/bin/bash"
    "/run/current-system/sw/bin/bash"
    "/bin/bash"
    "/usr/bin/bash"
  ];

  # Import shared and Darwin-specific modules
  imports = [
    ../../modules/darwin
    ../../modules/shared
  ];
}
