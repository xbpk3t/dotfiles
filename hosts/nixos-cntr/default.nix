{
  lib,
  myvars,
  ...
}: let
  inherit (myvars.networking) nameservers;
in {
  imports = [
  ];

  # 容器模式
  boot.isContainer = true;

  # 容器不需要也不能安装引导器，强制全部禁用
  # 报错是在部署时尝试安装 GRUB，容器环境没有真实磁盘（/dev/nvme0n1p2），导致引导器安装失败。容器不
  #  需要引导器，应该彻底禁用。已在 hosts/nixos-cntr/default.nix 强制关闭 grub/systemd-boot，并设置
  #  device=nodev，避免再去装引导。
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    efi.efiSysMountPoint = lib.mkForce "/boot/efi";
    grub = {
      enable = lib.mkForce false;
      device = lib.mkForce "nodev";
    };
  };

  networking = {
    hostName = lib.mkDefault "nixos-vps";
    useDHCP = lib.mkDefault true;
    nameservers = lib.mkDefault nameservers;
    useHostResolvConf = lib.mkForce false;
  };

  # 确保 root 公钥存在，否则 ssh 无法登陆（依赖 modules/nixos/base/ssh.nix 开启的 sshd）
  users.users.root.openssh.authorizedKeys.keys = myvars.mainSshAuthorizedKeys or [];

  # Ensure luck user exists for sops secrets ownership in container.
  users.users.luck = {
    isNormalUser = true;
    home = "/home/luck";
    createHome = true;
  };

  services.resolved = {
    enable = lib.mkDefault true;
    fallbackDns = nameservers;
  };

  # !!!
  # boot.isContainer = true;

  hardware.enableRedistributableFirmware = lib.mkForce false;

  # Disable scheduled upgrades to avoid conflicts with immutable deployments.
  system.autoUpgrade.enable = lib.mkForce false;
  systemd.services."nixos-upgrade".enable = lib.mkForce false;
  systemd.timers."nixos-upgrade".enable = lib.mkForce false;

  system.stateVersion = "24.11";
}
