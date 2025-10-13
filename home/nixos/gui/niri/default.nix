{
  config,
  lib,
  ...
} @ args: let
  cfg = config.modules.desktop.niri;
in {
  options.modules.desktop.niri = {
    enable = lib.mkEnableOption "niri compositor";
    settings = lib.mkOption {
      type = with lib.types; let
        valueType =
          nullOr (oneOf [
            bool
            int
            float
            str
            path
            (attrsOf valueType)
            (listOf valueType)
          ])
          // {
            description = "Niri configuration value";
          };
      in
        valueType;
      default = {};
    };
  };

  # 注意这里的手动import
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        programs.niri.settings = cfg.settings;
      }
      (import ./niri.nix args)
      (import ./xdg.nix args)
    ]
  );
}
