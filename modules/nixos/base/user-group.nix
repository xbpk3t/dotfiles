{
  myvars,
  pkgs,
  ...
}: {
  # Don't allow mutation of users outside the config.
  users.mutableUsers = false;

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
