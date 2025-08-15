# User management configuration
# Migrated from ansible/roles/common/tasks/users.yml and disk.yml
{ username, lib, ... }:

{
  # Create ops group and user (from ansible disk.yml)
  users.groups.ops = {};

  users.users = {
    # Main user configuration
    ${username} = {
      description = username;
      shell = "/bin/zsh"; # We use zsh everywhere
      # Platform-specific home directory will be set in platform modules
    };

    # Ops user (from ansible disk.yml)
    ops = {
      description = "Operations user";
      group = "ops";
      shell = "/bin/bash";
      createHome = true;
      # Platform-specific configuration in platform modules
    };
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;
}
