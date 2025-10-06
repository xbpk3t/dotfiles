# Darwin security configuration
{...}: {
  security = {
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
    sudo.extraConfig = ''
      # Environment variables to preserve
      Defaults env_keep += "EDITOR VISUAL PAGER"
      Defaults env_keep += "HOME XDG_*"
      Defaults env_keep += "SSH_AUTH_SOCK"
      Defaults env_keep += "KUBECONFIG"
      Defaults env_keep += "AWS_*"
      Defaults env_keep += "GOOGLE_*"
      Defaults env_keep += "DOCKER_*"

      # Security settings
      Defaults !tty_tickets
      Defaults !insults
      Defaults log_output
      Defaults loglinelen=0
      Defaults passwd_tries=3
      Defaults badpass_message="Password incorrect, please try again"
      Defaults passprompt="[sudo] password for %p: "
      Defaults secure_path="/etc/profiles/per-user/%p/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

      # Passwordless sudo for admin group (optional, uncomment if needed)
      # %admin ALL=(ALL) NOPASSWD: ALL
    '';

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
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # Note: pinentryPackage is not available on nix-darwin
    # Use pinentryFlavor instead or configure manually
  };

  # Note: System defaults are managed in system.nix to avoid duplication

  # Security-related environment variables
  environment.variables = {
    # GPG settings
    GPG_TTY = "$(tty)";
    GNUPGHOME = "$HOME/.gnupg";

    # SSH settings
    SSH_AUTH_SOCK = "$HOME/.ssh/ssh_auth_sock";

    # SOPS settings
    SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";

    # Security flags
    HISTCONTROL = "ignorespace:ignoredups";
    HISTIGNORE = "passwd *:password *:sudo -S *:su *:ssh *:gpg *:sops *";
  };
}
