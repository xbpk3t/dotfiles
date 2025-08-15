# Git configuration
# Migrated from ansible/roles/common/tasks/git.yml
{ useremail, username, ... }:

{
  # Global git configuration (equivalent to ansible git.yml)
  # This will be applied system-wide, but users can override in their home-manager config

  # Note: In Nix, we prefer to handle git config through home-manager
  # rather than system-wide configuration. The actual git config is in
  # home/git.nix and uses the same email/username values.

  # Ensure git is available system-wide
  environment.systemPackages = [ ];  # git is already in shared/packages.nix
}
