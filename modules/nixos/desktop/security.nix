{pkgs, ...}: {
  # 桌面特定：密钥/代理便捷功能
  # seahorse is a GUI App for GNOME Keyring.
  programs.seahorse.enable = true;

  # The OpenSSH agent remembers private keys for you
  # so that you don’t have to type in passphrases every time you make an SSH connection.
  # Use `ssh-add` to add a key to the agent.
  programs.ssh.startAgent = true;

  # gpg agent with pinentry
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-qt;
    # default-cache-ttl in seconds (4 hours)
    settings.default-cache-ttl = 4 * 60 * 60;
    enableSSHSupport = false;
  };
}
