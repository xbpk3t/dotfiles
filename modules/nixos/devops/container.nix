{
  config,
  lib,
  ...
}:
{
  options.modules.base.container = {
    enable = lib.mkEnableOption "Container optimization settings";
  };

  config = lib.mkIf config.modules.base.container.enable {
    boot = {
      # 引导器：容器由宿主机管理启动，容器内 boot loader 无意义
      # mkForce：这些选项在 NixOS 模块系统中优先级极高，不用 mkForce 无法覆盖
      loader = {
        grub.enable = lib.mkForce false;
        systemd-boot.enable = lib.mkForce false;
        efi.canTouchEfiVariables = lib.mkForce false;
      };
    };

    documentation = {
      # 文档：容器环境下文档可关闭以减少闭包体积，但允许宿主机按需覆盖
      # mkDefault：文档选项通常无强冲突，保留覆盖灵活性
      enable = lib.mkDefault false;
      doc.enable = lib.mkDefault false;
      info.enable = lib.mkDefault false;
      man.enable = lib.mkDefault false;
      nixos.enable = lib.mkForce false;
    };

    # 固件：容器共享宿主机内核，无需 redistributable firmware
    # mkForce：同引导器，防止硬件模块默认启用固件
    hardware.enableRedistributableFirmware = lib.mkForce false;
  };
}
