# Darwin security configuration
{ lib, config, ... }:
let
  cfg = config.modules.darwin.sec;
in
{
  options.modules.darwin.sec.enable =
    lib.mkEnableOption "macOS security baseline (PAM / sudo / CA certs)";

  config.security = lib.mkIf cfg.enable {
    # PAM configuration
    pam = {
      services = {
        sudo_local = {
          enable = true;
          touchIdAuth = true;
          watchIdAuth = true;
        };
      };
    };

    # Sudo configuration
    sudo.extraConfig = builtins.readFile ../infra/sudo.conf;

    # Certificate management
    pki = {
      installCACerts = true;
      certificateFiles = [
        # Add custom CA certificates here
        # ./certs/my-ca.crt
      ];
    };
  };

  # GPG configuration
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   # Note: pinentryPackage is not available on nix-darwin
  #   # Use pinentryFlavor instead or configure manually
  # };

  # Note: System defaults are managed in system.nix to avoid duplication
}
