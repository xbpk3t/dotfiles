{ ... }:

{
  # Shared macOS system preferences
  system = {
    # Shared system defaults
    defaults = { };

    # Shared system settings that can be applied across hosts
    # Note: Host-specific settings like primaryUser should be configured per-host
  };

  # Enable zsh shell
  programs.zsh.enable = true;

  # Shared system state version
  # Note: This should be host-specific and is kept here as an example
  # In practice, system.stateVersion should be set in host-specific configuration
  # system.stateVersion = 6;
}
