{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption mkDefault types;
  inferredDesktop =
    (config.services.xserver.enable or false)
    || (config.modules.desktop.gnome.enable or false);
in {
  options.modules.roles = {
    isDesktop = mkOption {
      type = types.bool;
      default = false;
      description = "标记是否为桌面角色；未设置时可使用自动推导。";
    };
    isServer = mkOption {
      type = types.bool;
      default = false;
      description = "标记是否为服务器角色；未设置时可使用 !isDesktop 作为默认。";
    };
  };

  config.modules.roles = {
    isDesktop = mkDefault inferredDesktop;
    isServer = mkDefault (!inferredDesktop);
  };
}
