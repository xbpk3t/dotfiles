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
    sudo.extraConfig = builtins.readFile ./sudo.conf;

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
  # modules/darwin/sec.nix 若仍需系统级环境变量，最好用绝对路径（如 /Users/<username>/.gnupg）并在 shell profile 中再动态调整 GPG_TTY。
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
