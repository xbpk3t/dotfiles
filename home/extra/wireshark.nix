{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.extra.wireshark;
in
{
  options.modules.extra.wireshark = with lib; {
    enable = mkEnableOption "Wireshark user-space tools";
  };

  config = lib.mkIf cfg.enable {

  };
}
