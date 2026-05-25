{
  config,
  lib,
  ...
}: {
  options.modules.base.container = {
    enable = lib.mkEnableOption "Container optimization settings";
  };

  config = lib.mkIf config.modules.base.container.enable {
    # Container 无需引导器（由宿主机管理）
    boot.loader.grub.enable = lib.mkForce false;
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

    # 容器无需文档
    documentation.enable = lib.mkDefault false;
    documentation.doc.enable = lib.mkDefault false;
    documentation.info.enable = lib.mkDefault false;
    documentation.man.enable = lib.mkDefault false;
    documentation.nixos.enable = lib.mkDefault false;

    # 容器无需固件
    hardware.enableRedistributableFirmware = lib.mkForce false;
  };
}
