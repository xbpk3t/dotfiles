{
  username,
  inputs ? {},
  pkgs,
  lib,
  ...
}: {
  # import sub modules
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./bash.nix
    ./git.nix
    ./neovim.nix

    ./ssh.nix
    ./rclone.nix
    ./fastfetch.nix
    ./gh.nix
    ./go.nix
    ./jq.nix
    ./pandoc.nix
    ./ripgrep.nix
    ./uv.nix

    ./gpg.nix
    ./direnv.nix
    ./cc.nix

    ./fzf.nix
    ./nix.nix
    ./yazi.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    inherit username;
    # Set home directory based on the system type
    homeDirectory = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then "/Users/${username}"
      else "/home/${username}"
    );

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";
  };

  # 环境变量
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "google-chrome";
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_COLLATE = "C"; # Avoids locale lookup errors
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
