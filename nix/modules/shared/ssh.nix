# SSH configuration
# Migrated from ansible/roles/common/tasks/ssh.yml
{ lib, ... }:

{
  # SSH client configuration (equivalent to ansible ssh.yml client settings)
  programs.ssh = {
    # Disable strict host key checking (from ansible)
    extraConfig = ''
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null
    '';
  };

  # SSH server configuration is platform-specific:
  # - Darwin: Remote Login in System Preferences
  # - NixOS: services.openssh
  # Platform-specific configurations will be in platform modules
}
