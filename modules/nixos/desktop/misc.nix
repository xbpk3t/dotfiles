{
  config,
  lib,
  pkgs,
  myvars,
  ...
}: {
  boot.loader.timeout = lib.mkForce 10; # wait for x seconds to select the boot entry

  # add user's shell into /etc/shells
  environment.shells = with pkgs; [
    bashInteractive
    nushell
  ];
  # set user's default shell system-wide
  users.defaultUserShell = pkgs.bashInteractive;

  # fix for `sudo xxx` in kitty/wezterm/foot and other modern terminal emulators
  security.sudo.keepTerminfo = true;

  environment.variables = {
    # fix https://github.com/NixOS/nixpkgs/issues/238025
    TZ = "${config.time.timeZone}";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    gnumake
    wl-clipboard
  ];

  services = {
    gvfs.enable = true; # Mount, trash, and other functionalities

    # 默认开启，TRIM 命令通知 SSD 哪些数据块不再使用（已被删除），从而允许 SSD 在空闲时提前擦除这些块，减少写入时的延迟。SSD 的存储单元有有限的写入/擦除次数（P/E 周期）。TRIM 帮助 SSD 更高效地管理空闲块，减少不必要的擦除操作，从而延长 SSD 的寿命。
    fstrim.enable = true;
    tumbler.enable = true; # Thumbnail support for images

    # 用来监控disk健康状态，并且disk有问题之前预警。开启后，NixOS会在系统启动时运行该服务。
    smartd = {
      enable = lib.mkDefault false;
      autodetect = true;
      notifications = {
        # 发生错误时发送邮件（需要系统邮件服务已配置）
        mail.enable = true;
        mail.recipient = "${myvars.mail}";
      };
    };
  };

  programs = {
    # dconf is a low-level configuration system.
    dconf.enable = true;

    # thunar file manager(part of xfce) related options
    # FIXME 暂时禁用，如果有问题再说
    #    thunar = {
    #      enable = true;
    #      plugins = with pkgs.xfce; [
    #        thunar-archive-plugin
    #        thunar-volman
    #      ];
    #    };
  };
}
