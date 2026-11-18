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

      # 2026-10 eMudhra / Comodo AAA Services root 私钥泄露事件。
      # nixpkgs cacert 移除该根证书后删除本条目。
      # https://emudhra.we-have-a-problem.com/
      caCertificateBlacklist = [ "Comodo AAA Services root" ];
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
