{
  myvars,
  pkgs,
  ...
}: {
  # Don't allow mutation of users outside the config.
  users.mutableUsers = false;

  users.groups = {
    "${myvars.username}" = {};
    podman = {};
    wireshark = {};
    # for android platform tools's udev rules
    adbusers = {};
    dialout = {};
    # for openocd (embedded system development)
    plugdev = {};
    # misc
    uinput = {};
  };

  users.users."${myvars.username}" = {
    # we have to use initialHashedPassword here when using tmpfs for /
    inherit (myvars) initialHashedPassword;
    home = "/home/${myvars.username}";
    isNormalUser = true;
    shell = pkgs.zsh; # 显式设置用户 shell 为 zsh

    # !!! 需要添加该配置，否则无法使用 ssh luck@host 登录目标host
    openssh.authorizedKeys.keys =
      myvars.mainSshAuthorizedKeys ++ myvars.secondaryAuthorizedKeys;

    extraGroups = [
      myvars.username
      "users"
      "wheel"
      "networkmanager" # for nmtui / nm-connection-editor
      "nix-users" # allow nix-daemon access
      "docker"
      "podman"
      "wireshark"
      "adbusers" # android debugging
      "libvirtd" # virt-viewer / qemu
      "input" # allow input event access (xremap etc.)
      "uinput" # allow creating virtual input devices
    ];
  };

  # root's ssh key are mainly used for remote deployment
  users.users.root = {
    inherit (myvars) initialHashedPassword;
    shell = pkgs.zsh; # 设置 root shell 为 zsh
    openssh.authorizedKeys.keys = myvars.mainSshAuthorizedKeys ++ myvars.secondaryAuthorizedKeys;
  };
}
