# Darwin user configuration
{ username, ... }:

{
  # User configuration for macOS
  users.users = {
    # Main user (already exists on macOS)
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
      # Note: Group membership on macOS is handled differently
    };
  };

  # Note: macOS user/group management is more complex than Linux
  # Additional configuration may be needed for full compatibility
}
