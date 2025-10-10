{ config, pkgs, lib, ... }:

let
  cfg = config.modules.networking.singbox;
in {
  options.modules.networking.singbox = {
    enable = lib.mkEnableOption "sing-box service";
  };

  config = lib.mkIf cfg.enable {

    home.packages = [ pkgs.sing-box ];

    # Configure launchd service for sing-box on Darwin
    launchd.agents.sing-box = {
      enable = true;
      config = {
        ProgramArguments = [
          "${pkgs.sing-box}/bin/sing-box"
          "run"
          "-c"
          "${config.home.homeDirectory}/.config/sing-box/config.json"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${config.home.homeDirectory}/.config/sing-box/sing-box.log";
        StandardErrorPath = "${config.home.homeDirectory}/.config/sing-box/sing-box.log";
      };
    };

    home.file.".config/sing-box/config.json".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/config.json";
  };
}