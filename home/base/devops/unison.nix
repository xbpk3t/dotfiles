{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.devops.unison;
  isLinux = pkgs.stdenv.hostPlatform.isLinux;
in
{
  # host 侧调用示例：
  # modules.devops.unison = {
  #   enable = true;
  #   pairs.goland-scratches = {
  #     roots = [
  #       "/home/luck/.local/share/JetBrains/GoLand/scratches"
  #       "ssh://luck@homelab//home/luck/.local/share/JetBrains/GoLand/scratches"
  #     ];
  #     commandOptions = {
  #       repeat = "watch";
  #       sshcmd = "${pkgs.openssh}/bin/ssh";
  #     };
  #   };
  # };
  options.modules.devops.unison = with lib; {
    enable = mkEnableOption "Declarative Unison sync pairs";

    pairs = mkOption {
      type = with types; attrsOf attrs;
      default = { };
      description = "Direct passthrough to Home Manager services.unison.pairs.";
    };
  };

  config = lib.mkIf cfg.enable {
    # https://mynixos.com/home-manager/options/services.unison
    services.unison = {
      # 注意只支持linux
      enable = isLinux;
      pairs = lib.mkIf isLinux cfg.pairs;
    };
  };
}
