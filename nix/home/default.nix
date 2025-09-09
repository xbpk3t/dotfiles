{ username ? "luck", inputs ? {}, pkgs, lib, ... }:

{
  # import sub modules
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./bash.nix
    ./core.nix
    ./git.nix
    ./neovim.nix

    # 添加SSH配置模块
    ./ssh.nix
    # 添加rclone配置模块
    ./rclone.nix
    # 新增的工具配置模块

    ./fastfetch.nix
    ./gh.nix
    ./go.nix
    ./jq.nix
    ./pandoc.nix
    ./ripgrep.nix
    ./uv.nix

    ./starship.nix
    ./gpg.nix
    ./direnv.nix
  ];

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    inherit username;
    # Set home directory based on the system type
    homeDirectory = lib.mkForce (if pkgs.stdenv.isDarwin
                                then "/Users/${username}"
                                else "/home/${username}");

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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
