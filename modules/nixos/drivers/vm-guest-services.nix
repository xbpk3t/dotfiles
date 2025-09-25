{
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.vm.guest-services;
in {
  options.vm.guest-services = {
    enable = mkEnableOption "Enable Virtual Machine Guest Services";
  };

  config = mkIf cfg.enable {
    services = {
      qemuGuest.enable = true;
      spice-vdagentd.enable = true;
      spice-webdavd.enable = false; #Causes build failure davsfs2 unsupported neon version 9-12-25
    };
  };
}
