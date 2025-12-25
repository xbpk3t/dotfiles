{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  cfg = config.modules.extra.vscode-remote;
in {
  options.modules.extra.vscode-remote = with lib; {
    enable = mkEnableOption "Enable VSCode Server (remote SSH target)";
  };

  config = lib.mkIf cfg.enable {
    imports = [inputs.vscode-server.nixosModules.default];

    services.vscode-server = {
      enable = true;
      enableFHS = true;
      nodejsPackage = pkgs.nodejs_20;
      extraRuntimeDependencies = with pkgs; [git bashInteractive coreutils];
      installPath = ["$HOME/.vscode-server" "$HOME/.vscode-server-insiders"];
    };
  };
}
