{
  config,
  lib,
  myvars,
  ...
}: let
  isContainer = config.boot.isContainer or false;
  containerFlakePath = "/etc/nixos";
  hostFlakePath = myvars.projectRoot or containerFlakePath;
in {
  boot.loader.systemd-boot = {
    # we use Git for version control, so we don't need to keep too many generations.
    configurationLimit = lib.mkDefault 10;
    # pick the highest resolution for systemd-boot's console.
    consoleMode = lib.mkDefault "max";
  };

  boot.loader.timeout = lib.mkDefault 8; # wait for x seconds to select the boot entry

  # Ensure nix tooling resolves the flake inside OCI containers instead of relying on host paths.
  programs.nh.flake =
    if isContainer
    then lib.mkForce containerFlakePath
    else lib.mkDefault hostFlakePath;

  environment.sessionVariables = lib.mkMerge [
    (lib.mkIf (!isContainer) {
      FLAKE = lib.mkDefault hostFlakePath;
      NIXOS_CONFIG = lib.mkDefault hostFlakePath;
    })
    (lib.mkIf isContainer {
      FLAKE = lib.mkForce containerFlakePath;
      NIXOS_CONFIG = lib.mkForce containerFlakePath;
    })
  ];

  nix.settings.trusted-users = lib.mkDefault ["root" "@wheel"];
}
