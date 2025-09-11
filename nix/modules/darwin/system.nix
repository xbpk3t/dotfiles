{...}: {
  # Shared macOS system preferences
  system = {
    # Shared system defaults
    defaults = {};
  };

  # System state version - this is host-specific and should not be changed after initial installation
  system.stateVersion = 6;

  # Enable zsh shell
  programs.zsh.enable = false;
}
