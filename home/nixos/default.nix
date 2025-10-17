{mylib, ...}: {
  # PLAN [2025-10-08] 弄清楚为啥这里不能
  imports = [../base] ++ mylib.scanPaths ./.;

  #  # Home Manager needs a bit of information about you and the
  #  # paths it should manage.
  #  home = {
  #    inherit (myvars) username;
  #
  #    # This value determines the Home Manager release that your
  #    # configuration is compatible with. This helps avoid breakage
  #    # when a new Home Manager release introduces backwards
  #    # incompatible changes.
  #    #
  #    # You can update Home Manager without changing this value. See
  #    # the Home Manager release notes for a list of state version
  #    # changes in each release.
  #    stateVersion = "24.11";
  #
  #    # Basic session variables
  #    sessionVariables = {
  #      EDITOR = "nvim";
  #      VISUAL = "nvim";
  #    };
  #  };

  # 禁用指定工具的stylix配置
  stylix.targets = {
    rofi.enable = false;
    # 配置 Firefox profile names 以避免 stylix warning
    firefox.profileNames = ["default"];
  };

  # Basic packages and configurations can be added here
  # For example:
  # home.packages = [ pkgs.hello ];
}
