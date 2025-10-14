{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.desktop.shell;
in {
  #############################################################################
  # Desktop Shell Module - Manages Noctalia and DMS systemd services
  #
  # 这个模块管理桌面 shell 的 systemd 服务配置
  # 支持 Noctalia 和 DankMaterialShell (DMS)
  #
  # 注意：
  # - 这里只配置 NixOS 级别的 systemd 服务
  # - home-manager 级别的配置在 home/nixos/gui/noctalia.nix 和 DMS.nix 中
  # - 两者需要保持一致才能正常工作
  #############################################################################

  options.modules.desktop.shell = {
    noctalia = {
      enable = mkEnableOption "noctalia shell systemd service";

      target = mkOption {
        type = types.str;
        default = "graphical-session.target";
        description = "Systemd target for noctalia shell service";
      };
    };

    dms = {
      enable = mkEnableOption "DankMaterialShell systemd service";

      target = mkOption {
        type = types.str;
        default = "graphical-session.target";
        description = "Systemd target for DMS service";
      };
    };
  };

  config = mkMerge [
    #---------------------------------------------------------------------------
    # NOCTALIA CONFIGURATION
    #---------------------------------------------------------------------------
    (mkIf cfg.noctalia.enable {
      # Noctalia shell service
      # 注意：需要 target，否则需要手动启动
      services.noctalia-shell = {
        enable = true;
        target = cfg.noctalia.target;
      };
    })

    #---------------------------------------------------------------------------
    # DMS CONFIGURATION
    #---------------------------------------------------------------------------
    (mkIf cfg.dms.enable {
      # DMS 通过 home-manager 的 systemd.user.services 配置
      # 这里不需要额外的 NixOS 级别配置
      # 参考 home/nixos/gui/DMS.nix 中的 enableSystemd 选项
    })

    #---------------------------------------------------------------------------
    # ASSERTIONS - 确保不会同时启用两个 shell
    #---------------------------------------------------------------------------
    {
      assertions = [
        {
          assertion = !(cfg.noctalia.enable && cfg.dms.enable);
          message = "Cannot enable both noctalia and DMS at the same time. Please choose one.";
        }
      ];
    }
  ];
}
