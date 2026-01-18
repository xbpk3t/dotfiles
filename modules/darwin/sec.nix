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
      # Keep Nix-related paths/certs so sudoed nix stays usable
      Defaults env_keep += "PATH NIX_PATH NIX_SSL_CERT_FILE"

      # Security settings
      Defaults !tty_tickets
      Defaults !insults
      Defaults log_output
      Defaults loglinelen=0
      Defaults passwd_tries=3
      Defaults badpass_message="Password incorrect, please try again"
      Defaults passprompt="[sudo] password for %p: "
      # 依次是 Determinate Nix
      Defaults secure_path="/nix/var/nix/profiles/default/bin:/etc/profiles/per-user/%p/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

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
  # TODO: 看看是否真的需要，如果不需要就删除掉
  # modules/darwin/sec.nix:63-74 把 GPG_TTY="$(tty)", GNUPGHOME="$HOME/.gnupg" 等写成字面量，launchd 设置环境不会做变量或命令展开，实际值会是包含 $ 的字符串，gpg/ssh/sops 路径全失效；改成绝对路径或在交互 shell 中 export GPG_TTY=$(tty)。
  # modules/darwin/sec.nix 若仍需全局环境变量，最好用绝对路径（如 /Users/${myvars.username}/.gnupg）并在 shell profile 中再动态调整 GPG_TTY。
  #  environment.variables = {
  #    # GPG settings
  #    GPG_TTY = "$(tty)";
  #    GNUPGHOME = "$HOME/.gnupg";
  #
  #    # SSH settings
  #    SSH_AUTH_SOCK = "$HOME/.ssh/ssh_auth_sock";
  #
  #    # SOPS settings
  #    SOPS_AGE_KEY_FILE = "$HOME/.config/sops/age/keys.txt";
  #
  #    # Security flags
  #    HISTCONTROL = "ignorespace:ignoredups";
  #    HISTIGNORE = "passwd *:password *:sudo -S *:su *:ssh *:gpg *:sops *";
  #  };
}
