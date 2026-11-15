{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.kernel.fhs;
in
{
  options.modules.kernel.fhs.enable = lib.mkEnableOption "FHS environment (appimage/flatpak support)";

  # FHS environment, flatpak, appImage, etc.
  config.environment.systemPackages = lib.optionals cfg.enable [
    # create a fhs environment by command `fhs`, so we can run non-nixos packages in nixos!
    (
      let
        base = pkgs.appimageTools.defaultFhsEnvArgs;
      in
      pkgs.buildFHSEnv (
        base
        // {
          name = "fhs";
          targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [ pkgs.pkg-config ];
          profile = "export FHS=1";
          runScript = "zsh";
          extraOutputsToInstall = [ "dev" ];
        }
      )
    )
  ];
}
