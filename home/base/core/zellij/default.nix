{...}: {
  # Zellij configuration using KDL format
  # Reference: https://github.com/zellij-org/awesome-zellij
  # Plugins: zjstatus, zellij-forgot, room

  programs.zellij = {
    enable = true;
    # Note: We use KDL configuration file instead of Nix attrset
    # This allows for better plugin support and more flexible configuration
  };

  # Deploy KDL configuration file
  xdg.configFile."zellij/config.kdl".source = ./config.kdl;

  # only works in bash/zsh, not nushell
  home.shellAliases = {
    "zz" = "zellij";
  };
}
