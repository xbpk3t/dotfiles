# Darwin user configuration
# Contains user configuration that can be shared between multiple hosts
{
  username,
  lib,
  ...
}: {
  # Default user configuration (can be overridden by host-specific settings)
  users.users = {
    # Main user configuration with defaults
    ${username} = {
      home = lib.mkDefault "/Users/${username}";
      description = lib.mkDefault username;
      shell = lib.mkDefault "/etc/profiles/per-user/${username}/bin/bash";
    };

    # Note: Additional users should be created manually on macOS or via host-specific configuration
  };

  # Default Nix settings (can be overridden by host-specific settings)
  nix.settings.trusted-users = lib.mkDefault [username];

  # Shell configuration - only bash and zsh (no fish as not used)
  environment.shells = lib.mkDefault [
    #  "/etc/profiles/per-user/${username}/bin/zsh"
    #  "/run/current-system/sw/bin/zsh"
    #  "/bin/zsh"
    #  "/usr/bin/zsh"

    "/etc/profiles/per-user/${username}/bin/bash"
    #  "/run/current-system/sw/bin/bash"
    #  "/bin/bash"
    #  "/usr/bin/bash"
  ];

  environment.pathsToLink = lib.mkDefault [
    # "/share/zsh"
    # "/share/bash-completion"
    # "/share/nvim"
    # "/share/man"
  ];
}
