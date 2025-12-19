{
  myvars,
  pkgs,
  ...
}: {
  # Don't allow mutation of users outside the config.
  users.mutableUsers = false;

  # 设置系统默认用户 shell
  # 这会影响新创建的用户和通过 users.defaultUserShell 设置的用户
  users.defaultUserShell = pkgs.zsh;
  programs = {
    # 必须在modules里让zsh生效（但是具体bash, zsh的自定义配置则放到hm里），否则会报错
    bash.enable = true;
    zsh.enable = true;
  };

  # ===== Shell 相关环境变量 =====
  # 可以在这里添加 shell 相关的全局环境变量
  # environment.variables = {
  #   SHELL = "${pkgs.zsh}/bin/zsh";
  # };

  users.groups = {
    "${myvars.username}" = {};
    dialout = {};
    # for openocd (embedded system development)
    plugdev = {};
  };

  # root's ssh key are mainly used for remote deployment
  users.users.root = {
    inherit (myvars) initialHashedPassword;
    # 设置 root shell 为 zsh
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = myvars.mainSshAuthorizedKeys ++ myvars.secondaryAuthorizedKeys;
  };

  users.users."${myvars.username}" = {
    # we have to use initialHashedPassword here when using tmpfs for /
    inherit (myvars) initialHashedPassword;
    home = "/home/${myvars.username}";
    isNormalUser = true;
    # 显式设置用户 shell 为 zsh
    shell = pkgs.zsh;

    # !!! 需要添加该配置，否则无法使用 ssh luck@host 登录目标host
    openssh.authorizedKeys.keys =
      myvars.mainSshAuthorizedKeys ++ myvars.secondaryAuthorizedKeys;

    extraGroups = [
      myvars.username
      "users"
      "wheel"
      "networkmanager" # for nmtui / nm-connection-editor
      "nix-users" # allow nix-daemon access
      "input" # allow input event access (xremap etc.)
    ];
  };
}
