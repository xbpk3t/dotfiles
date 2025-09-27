{myvars, ...}: {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    inherit (myvars) username;

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.11";

    # Basic session variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  # Basic packages and configurations can be added here
  # For example:
  # home.packages = [ pkgs.hello ];

  # Import GUI and other configurations for this user
  imports = [
    ../base/default.nix
    ../base/tui
    ../base/gui
    ./gui
    # ./cli.nix
    # ./development.nix
  ];
}
