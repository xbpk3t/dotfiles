{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.desktop.gnome;
in {
  options.modules.desktop.gnome = {
    enable = mkEnableOption "GNOME desktop";
  };

  config = mkIf cfg.enable {
    systemd.defaultUnit = "graphical.target";

    hardware.bluetooth.enable = true;

    services = {
      xserver = {
        enable = true;
      };

      displayManager.gdm = {
        enable = true;
        wayland = true;
      };

      desktopManager = {
        gnome.enable = true;
      };

      gnome = {
        gnome-keyring.enable = true;
        # Use gnome keyring's SSH Agent
        # https://wiki.gnome.org/Projects/GnomeKeyring/Ssh
        gcr-ssh-agent.enable = false;
      };

      # 确保 greetd/其他 DM 不再启用，避免冲突
      # GNOME 走 gdm + gnome-shell，Wayland 优先
      greetd.enable = false;

      # 挂载/回收站等桌面功能
      # GNOME 的回收站/挂载/网络位置依赖它，NixOS gnome 模块未必自动开启，建议保留。
      gvfs.enable = true;
      udisks2.enable = true;
      # 开缩略图守护进程（会自动带上对应包）
      tumbler.enable = true;

      # enable bluetooth & gui pairing tools - blueman
      # or you can use cli:
      # $ bluetoothctl
      # [bluetooth] # power on
      # [bluetooth] # agent on
      # [bluetooth] # default-agent
      # [bluetooth] # scan on
      # ...put device in pairing mode and wait [hex-address] to appear here...
      # [bluetooth] # pair [hex-address]
      # [bluetooth] # connect [hex-address]
      # Bluetooth devices automatically connect with bluetoothctl as well:
      # [bluetooth] # trust [hex-address]
      blueman.enable = true;
    };

    # GNOME 依赖 dconf
    programs.dconf.enable = true;

    # 基础 GNOME 工具
    environment.systemPackages = with pkgs; [
      gnome-tweaks
      gnomeExtensions.appindicator
    ];

    # KDE Connect 端口仅在 GNOME 桌面启用时开放
    networking.firewall = {
      allowedTCPPorts = [
        1714
        1764
      ];
      allowedUDPPorts = [
        1714
        1764
      ];
    };
  };
}
