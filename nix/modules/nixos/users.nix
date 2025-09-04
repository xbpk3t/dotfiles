# NixOS user management
# Contains user configuration that can be shared between multiple hosts
{ ... }:

{
  # Shared user configuration patterns
  users.users = { };

  # Shared security configuration
  security = {
    # Shared sudo configuration patterns
    # Note: Specific sudo settings should be configured per-host
    # sudo.wheelNeedsPassword = false;
  };
}
