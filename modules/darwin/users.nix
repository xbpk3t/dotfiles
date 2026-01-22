# Darwin user configuration
# Contains user configuration that can be shared between multiple hosts
{
  myvars,
  lib,
  pkgs,
  ...
}: {
  # Default user configuration (can be overridden by host-specific settings)
  users.users = {
    # Main user configuration with defaults
    "${myvars.username}" = {
      home = "/Users/${myvars.username}";
      description = myvars.username;
      shell = lib.mkDefault (pkgs.zsh + "/bin/zsh");
      openssh.authorizedKeys.keys = myvars.SSHPubKeys;
    };

    # Note: Additional users should be created manually on macOS or via host-specific configuration
  };

  # Default Nix settings (can be overridden by host-specific settings)
  nix.settings.trusted-users = lib.mkDefault [myvars.username];

  # Shell configuration - make shells available system-wide
  environment.shells = lib.mkDefault [
    (pkgs.zsh + "/bin/zsh")
    (pkgs.bash + "/bin/bash")
  ];

  environment.pathsToLink = lib.mkDefault [
    # "/share/zsh"
    # "/share/bash-completion"
    # "/share/nvim"
    # "/share/man"
  ];
}
